"""
Mock GDB server.
"""

from __future__ import print_function

import re
import socket
import sys
import threading

from six.moves import socketserver
from six import iterbytes


XDIGIT = b'[0-9a-fA-F]'


def _log(message, sink=sys.stdout):
    """Output a log message produced by the mock."""

    print('lldbsmock: {}'.format(message), file=sink)


def setup_pseudo(remote):
    """
    Set up the system to look like a machine with a simple pseudo-architecture.
    """

    remote.triple = 'aarch64-unknown-none-elf'

    rc = {'bitsize': 64, 'encoding': 'uint', 'format_': 'hex',
          'set_': 'General Purpose Registers'}
    remote.registers = Registers([
        Register('x0', offset=0, value=RegisterValue(64), **rc),
        Register('x1', offset=8, value=RegisterValue(64), **rc),
        Register('x2', offset=16, value=RegisterValue(64), **rc),
        Register('x3', offset=24, value=RegisterValue(64), **rc),
        Register('x4', offset=32, value=RegisterValue(64), **rc),
        Register('x5', offset=40, value=RegisterValue(64), alt_name='fp',
                 generic='fp', **rc),
        Register('x6', offset=48, value=RegisterValue(64), alt_name='lr',
                 generic='ra', **rc),
        Register('sp', offset=56, value=RegisterValue(64), generic='sp', **rc),
        Register('pc', offset=64, value=RegisterValue(64), generic='pc', **rc),
        Register('cpsr', offset=72, value=RegisterValue(64), generic='fr',
                 **rc),
    ])

    # 4kB memory.
    memory_content = [0x00] * 4096
    remote.memory = Memory(memory_content)


def setup_morello(remote):
    """Set up the system to look like a Morello machine."""

    remote.triple = 'aarch64-none-elf'

    # c0-30, csp_el0, rcsp_el0, pc[c], ddc_el0, rddc_el0
    rv = [RegisterValue(129) for _ in range(36)]

    gpr_desc = {'bitsize': 64, 'encoding': 'uint', 'format_': 'hex',
            'set_': 'General Purpose Registers'}
    cap_desc = {'bitsize': 129, 'encoding': 'capability', 'format_': 'hex',
            'set_': 'Capability Registers'}
    cap_state_desc = {'bitsize': 129, 'encoding': 'capability', 'format_': 'hex',
            'set_': 'Capability State Registers'}

    csp_res = RegisterValueStateResolver(rv[33], 111, rv[31], rv[32])
    ddc_res = RegisterValueStateResolver(rv[33], 111, rv[34], rv[35])

    remote.registers = Registers(
            # General purpose registers (xN)
            [Register('x{}'.format(N), offset=N * 8, value=rv[N], gcc=N, dwarf=N,
                **gpr_desc) for N in range(29)] +
            [Register('x29', offset=232, value=rv[29], gcc=29, dwarf=29,
                alt_name='fp', generic='fp', **gpr_desc),
            Register('x30', offset=240, value=rv[30], gcc=30, dwarf=30,
                alt_name='lr', generic='ra', **gpr_desc),
            # State registers
            Register('sp', offset=248, value=csp_res, gcc=31, dwarf=31, generic='sp',
                **gpr_desc),
            Register('pc', offset=256, value=rv[33], generic='pc', **gpr_desc)] +
            # Capability registers (cN)
            [Register('c{}'.format(N), offset=264 + N * 17, value=rv[N],
                gcc=198 + N, dwarf=198 + N, **cap_desc) for N in range(30)] +
            [Register('c30', offset=774, value=rv[30], gcc=228, dwarf=228,
                alt_name='clr', generic='rac', **cap_desc),
            Register('csp', offset=791, value=csp_res, gcc=229, dwarf=229,
                generic='csp', **cap_desc),
            Register('pcc', offset=808, value=rv[33], generic='pcc', **cap_desc),
            Register('ddc', offset=825, value=ddc_res, **cap_desc),
            # Capability state registers
            Register('sp_el0', offset=842, value=rv[31], **gpr_desc),
            Register('rsp_el0', offset=850, value=rv[32], **gpr_desc),
            Register('csp_el0', offset=867, value=rv[31], **cap_state_desc),
            Register('rcsp_el0', offset=884, value=rv[32], **cap_state_desc),
            Register('ddc_el0', offset=901, value=rv[34], **cap_state_desc),
            Register('rddc_el0', offset=918, value=rv[35], **cap_state_desc),
            ])

    # 4kB memory with a 1-byte tag per a 16-byte location.
    memory_content = [0x00] * 4096
    memory_tags = [0x00] * 256
    remote.memory = Memory(memory_content, memory_tags, 16, 1)
    remote.has_qXfer_capa_read = True


class RegisterValueInterface(object):
    """Interface that must be implemented by register values."""

    def register_view(self, register):
        """Record that a register provides a view for the value."""

        raise NotImplementedError

    def get_invalidate(self):
        """
        Return which registers should the debugger consider as invalid when the
        register value is modified. The returned value includes IDs of all
        registers that provide any view on the register value.
        """

        raise NotImplementedError

    def write(self, bitpos, bitsize, data):
        """Write specified data at [bitpos, bitpos+bitsize)."""

        raise NotImplementedError

    def read(self, bitpos, bitsize):
        """Read content at [bitpos, bitpos+bitsize)."""

        raise NotImplementedError


class RegisterValue(RegisterValueInterface):
    """Simple register value."""

    def __init__(self, bitsize):
        super(RegisterValue, self).__init__()
        self.value = 0
        self.bitsize = bitsize
        self.views = []

    def register_view(self, register):
        self.views.append(register)

    def get_invalidate(self):
        if len(self.views) < 2:
            return None
        return [i.get_register_file_id() for i in self.views]

    def write(self, bitpos, bitsize, data):
        assert bitpos >= 0
        assert bitpos + bitsize <= self.bitsize
        assert data < (1 << bitsize)
        self.value &= ((1 << self.value.bit_length()) - 1) ^ \
            (((1 << bitsize) - 1) << bitpos)
        self.value |= data << bitpos

    def read(self, bitpos, bitsize):
        assert bitpos >= 0
        assert bitpos + bitsize <= self.bitsize
        return (self.value >> bitpos) & ((1 << bitsize) - 1)


class RegisterValueStateResolver(RegisterValueInterface):
    """Register value that is dynamically resolved based on the state."""

    def __init__(self, state_value, state_bit, set_value, clear_value):
        super(RegisterValueStateResolver, self).__init__()
        self.state_value = state_value
        self.state_bit = state_bit
        self.set_value = set_value
        self.clear_value = clear_value

    def get_active_value(self):
        """Return the active register value based on the current state."""

        return self.set_value if self.state_value.read(self.state_bit, 1) \
            else self.clear_value

    def register_view(self, register):
        # Record views for all three register values as a change to them can
        # invalidate this value.
        self.state_value.register_view(register)
        self.set_value.register_view(register)
        self.clear_value.register_view(register)

    def get_invalidate(self):
        return list(set(self.set_value.get_invalidate() +
                        self.clear_value.get_invalidate()))

    def write(self, bitpos, bitsize, data):
        self.get_active_value().write(bitpos, bitsize, data)

    def read(self, bitpos, bitsize):
        return self.get_active_value().read(bitpos, bitsize)


class Register(object):
    """Machine register."""

    def __init__(self, name, offset, bitsize, encoding, format_, set_, value,
                 value_pos=0, gcc=None, dwarf=None, alt_name=None,
                 generic=None):
        self.id = None
        self.name = name
        self.offset = offset
        self.bitsize = bitsize
        self.encoding = encoding
        self.format = format_
        self.set = set_
        self.value = value
        self.value_pos = value_pos
        self.gcc = gcc
        self.dwarf = dwarf
        self.alt_name = alt_name
        self.generic = generic

        self.value.register_view(self)

    def set_register_file_id(self, id_):
        """Set ID of the register that it has in the parent register file."""

        self.id = id_

    def get_register_file_id(self):
        """Get ID of the register that it has in the parent register file."""

        return self.id

    def process_qRegisterInfo(self):
        """
        Process a "qRegisterInfo" request and return a response that should be
        sent to the debugger.
        """

        res = 'name:{};offset:{};bitsize:{};encoding:{};format:{};' \
              'set:{};'.format(self.name, self.offset, self.bitsize,
                               self.encoding, self.format, self.set)
        if self.gcc:
            res += 'gcc:{};'.format(self.gcc)
        if self.dwarf:
            res += 'dwarf:{};'.format(self.dwarf)
        if self.alt_name:
            res += 'alt-name:{};'.format(self.alt_name)
        if self.generic:
            res += 'generic:{};'.format(self.generic)
        invalidate = self.value.get_invalidate()
        if invalidate:
            res += 'invalidate-regs:{};'.format(
                ','.join(['{:x}'.format(i) for i in invalidate
                          if i != self.id]))
        return res.encode('ascii')

    def process_p(self, byte_order):
        """
        Process a "p" request (read register value) and return a response that
        should be sent to the debugger.
        """

        assert byte_order == 'little' or byte_order == 'big'

        value = self.value.read(self.value_pos, self.bitsize)
        bytes_ = []
        for _ in range((self.bitsize + 7) // 8):
            byte = value & 0xff
            value >>= 8
            fmt = format(byte, '02x').encode('ascii')
            bytes_.append(fmt)

        if byte_order == 'big':
            bytes_.reverse()
        return b''.join(bytes_)

    def process_P(self, byte_order, hexvalue):
        """
        Process a "P" request (write register value) and return a response that
        should be sent to the debugger.
        """

        assert byte_order == 'little' or byte_order == 'big'

        if len(hexvalue) != (self.bitsize + 7) // 8 * 2:
            return b'E01'

        if byte_order == 'little':
            hexvalue = b''.join(reversed(
                [hexvalue[i:i + 2] for i in range(0, len(hexvalue), 2)]))

        self.write(int(hexvalue, 16))
        return b'OK'

    def write(self, value):
        """Write the specified value to the register."""

        self.value.write(self.value_pos, self.bitsize, value)


class Registers(object):
    """Machine registers."""

    def __init__(self, list_):
        self.list_ = list_

        # Set position/ID of each register in the register file and build a
        # name map.
        self._name_map = {}
        for i, register in enumerate(self.list_):
            register.set_register_file_id(i)
            self._name_map[register.name] = i
            if register.alt_name is not None:
                self._name_map[register.alt_name] = i

    def __getitem__(self, key):
        try:
            return self.list_[key]
        except TypeError:
            pass
        return self.list_[self._name_map[key]]

    def __len__(self):
        return len(self.list_)


class Memory(object):
    """Addressable memory."""

    def __init__(self, content, tags=None, tag_granularity=0, tag_size=0):
        self.content = content
        self.tags = tags
        self.tag_granularity = tag_granularity
        self.tag_size = tag_size

    def process_m(self, addr, length):
        """
        Process an "m" request (read memory) and return a response that should
        be sent to the debugger.
        """

        bytes_ = [format(byte, '02x').encode('ascii')
                  for byte in self.content[addr:addr + length]]
        response = b''.join(bytes_)
        if len(response) != 0:
            return response
        return b'E01'

    def process_M(self, addr, length, hexvalue):
        """
        Process an "M" request (write memory) and return a response that should
        be sent to the debugger.
        """

        if len(hexvalue) != length * 2:
            return b'E01'
        if addr + length > len(self.content):
            return b'E01'

        self.content[addr:addr + length] = [
            int(hexvalue[i:i + 2], 16) for i in range(0, len(hexvalue), 2)]
        return b'OK'

    def process_qXfer_capa_read(self, addr, offset, length):
        """
        Process a "qXfer:capa:read" request (read tagged capability memory
        data) and return a binary response that should be sent to the debugger.
        """

        if self.tag_size != 1 or self.tag_granularity != 16:
            return b'E01'
        if addr % 16 != 0:
            return b'E01'

        data = [self.tags[addr // self.tag_granularity]] + \
            self.content[addr:addr + self.tag_granularity]
        selected = data[offset:offset + length]
        char = b'l' if offset + length >= len(data) else b'm'

        return char + bytes(bytearray(selected))

    def write(self, addr, bytes_, tags=None):
        """Write memory data at the specified address."""

        assert addr + len(bytes_) <= len(self.content)
        self.content[addr:addr + len(bytes_)] = bytes_

        if tags:
            assert addr % self.tag_granularity == 0
            assert len(bytes_) % self.tag_granularity == 0
            assert len(bytes_) // self.tag_granularity == len(tags)
            self.tags[addr // self.tag_granularity:
                      (addr + len(bytes_)) // self.tag_granularity] = tags


class GDBRequestHandler(socketserver.BaseRequestHandler, object):
    """Handler for a client connection to the mock GDB server."""

    # Connection state.
    STATE_HANDSHAKE = 0
    STATE_NEW_PACKET = 1
    STATE_PACKET_DATA = 2
    STATE_CHECKSUM = 3
    STATE_ACKNOWLEDGEMENT = 4

    # GDB signal numbers.
    SIGTRAP = 5

    def _get_packet_checksum(self, packet):
        """Return a checksum for the given packet data."""

        checksum = 0
        for byte in iterbytes(packet):
            checksum = (checksum + byte) % 256
        return checksum

    def _get_hex_string(self, string):
        """Return a hexadecimal representation of the given string."""

        return ''.join([format(ord(char), '02x') for char in string])

    def _process_packet(self, packet):
        """Process a single packet from the client."""

        # Default return value.
        res = not self._no_ack_mode

        if packet == b'QStartNoAckMode':
            self._no_ack_mode = True
            self._send_response(b'OK')
            return True
        if packet.startswith(b'qSupported:'):
            # Features supported by the client are received. As a response,
            # return what features are supported by the server.
            response = b'PacketSize=1fff;QStartNoAckMode'
            if self.has_qXfer_capa_read:
                response += b';qXfer:capa:read+'
            self._send_response(response)
            return res
        if packet == b'qC':
            # Return the current thread ID.
            self._send_response(b'QC 1')
            return res
        if packet == b'?':
            # Indicate the reason the target halted.
            self._send_response(b'S' +
                                format(self.SIGTRAP, '02x').encode('ascii'))
            return res
        if packet == b'Hg1':
            # Set thread 1 for subsequent operations.
            self._send_response(b'OK')
            return res
        if packet == b'qHostInfo':
            # Get information about the host.
            self._send_response('triple:{};endian:{};'.format(
                self._get_hex_string(self.triple),
                self.byte_order).encode('ascii'))
            return res
        if packet == b'qfThreadInfo':
            # Obtain a list of all active thread IDs.
            self._send_response(b'm1')
            return res
        if packet == b'qsThreadInfo':
            # Subsequent qfThreadInfo queries. Since there is only one thread
            # and that was reported by qfThreadInfo, return 'l' to indicate end
            # of list.
            self._send_response(b'l')
            return res
        match = re.match(b'^qRegisterInfo(' + XDIGIT + b'+)$', packet)
        if match:
            # Get register information.
            index = int(match.group(1), 16)
            if index < len(self.registers):
                register = self.registers[index]
                self._send_response(register.process_qRegisterInfo())
            else:
                self._send_response(b'E45')
            return res
        match = re.match(b'^p(' + XDIGIT + b'+)$', packet)
        if match:
            # Read register value.
            index = int(match.group(1), 16)
            if index < len(self.registers):
                register = self.registers[index]
                self._send_response(register.process_p(self.byte_order))
            else:
                self._send_response(b'E45')
            return res
        match = re.match(b'^P(' + XDIGIT + b'+)=(' + XDIGIT + b'+)$', packet)
        if match:
            # Write register value.
            index = int(match.group(1), 16)
            value = match.group(2)
            if index < len(self.registers):
                register = self.registers[index]
                self._send_response(register.process_P(self.byte_order, value))
            else:
                self._send_response(b'E45')
            return res
        match = re.match(b'^m(' + XDIGIT + b'+),(' + XDIGIT + b'+)$', packet)
        if match:
            # Read memory.
            addr = int(match.group(1), 16)
            length = int(match.group(2), 16)
            self._send_response(self.memory.process_m(addr, length))
            return res
        match = re.match(b'^M(' + XDIGIT + b'+),(' + XDIGIT + b'+):(' +
                         XDIGIT + b'+)$', packet)
        if match:
            # Write memory.
            addr = int(match.group(1), 16)
            length = int(match.group(2), 16)
            value = match.group(3)
            self._send_response(self.memory.process_M(addr, length, value))
            return res
        if self.has_qXfer_capa_read:
            match = re.match(b'^qXfer:capa:read:(' + XDIGIT + b'+):(' +
                             XDIGIT + b'+),(' + XDIGIT + b'+)$', packet)
            if match:
                # Read tagged memory.
                addr = int(match.group(1), 16)
                offset = int(match.group(2), 16)
                length = int(match.group(3), 16)
                self._send_binary_response(
                    self.memory.process_qXfer_capa_read(addr, offset, length))
                return res

        if self.server.trace:
            _log("Unrecognized packet {}.".format(packet))
        self._send_response(b'')
        return res

    def _send_raw_data(self, data):
        """Send raw data to the client."""

        self.request.sendall(data)
        if self.server.trace:
            if sys.version_info[0] < 3:
                # Encode possibly binary data for the output. Printing bytes in
                # Python 3 provides this behaviour by default.
                data = data.encode('string_escape')
            _log("-> {}".format(data))

    def _send_response(self, response):
        """Send a response to the client."""

        checksum = self._get_packet_checksum(response)
        self._send_raw_data(b'$' + response + b'#' +
                            format(checksum, '02x').encode('ascii'))

    def _send_binary_response(self, response):
        """Escape a binary response and send it to the client."""

        escaped_response = bytearray()
        for byte in iterbytes(response):
            if byte in (0x23, 0x24, 0x7d, 0x2a):
                escaped_response.append(0x7d)
                escaped_response.append(byte ^ 0x20)
            else:
                escaped_response.append(byte)
        self._send_response(bytes(escaped_response))

    def _packet_error(self, error):
        """
        Report the given error and inform the client that the packet was not
        acknowledged.
        """

        if self.server.trace:
            _log(error)
        self._send_raw_data(b'-')

    def setup(self):
        """Set up data for one client connection."""

        self._no_ack_mode = False

        # Initial target settings.
        self.triple = 'unknown-unknown-none-elf'
        self.byte_order = 'little'
        self.registers = Registers([])
        self.memory = Memory([])
        self.has_qXfer_capa_read = False

        if self.server.config:
            self.server.config(self)
        else:
            setup_pseudo(self)

    def handle(self):
        """Process a connection from a client."""

        if self.server.trace:
            _log("Received connection from {}:{}.".format(
                self.client_address[0], self.client_address[1]))

        data = b''
        state = self.STATE_HANDSHAKE
        packet_data = b''
        checksum = b''

        self.request.settimeout(self.server.client_timeout)

        exit_now = False
        while not exit_now:
            try:
                recv = self.request.recv(4096)
            except socket.timeout:
                _log("Receive operation on the client socket timed out.")
                break
            if len(recv) == 0:
                break

            if self.server.trace:
                _log("<- {}".format(recv))
            data += recv

            while not exit_now and len(data) > 0:
                # Process one byte.
                byte = data[:1]
                data = data[1:]

                if state == self.STATE_HANDSHAKE:
                    if byte != b'+':
                        self._packet_error("Expected '+' as a handshake but "
                                           "got {}.".format(byte))
                        exit_now = True
                        break
                    state = self.STATE_NEW_PACKET
                elif state == self.STATE_NEW_PACKET:
                    if byte != b'$':
                        self._packet_error(
                            "Expected '$' to indicate start of a new packet "
                            "but got {}.".format(byte))
                        exit_now = True
                        break
                    state = self.STATE_PACKET_DATA
                elif state == self.STATE_PACKET_DATA:
                    if byte == b'#':
                        state = self.STATE_CHECKSUM
                    else:
                        packet_data += byte
                elif state == self.STATE_CHECKSUM:
                    checksum += byte
                elif state == self.STATE_ACKNOWLEDGEMENT:
                    if byte != b'+':
                        self._packet_error(
                            "Expected '+' as an acknowledgement but got "
                            "{}.".format(byte))
                        exit_now = True
                        break
                    state = self.STATE_NEW_PACKET

                if len(checksum) != 2:
                    continue

                # Complete packet is received.

                # Verify checksum.
                packet_data_checksum = self._get_packet_checksum(packet_data)

                try:
                    expected_checksum = int(checksum, 16)
                except ValueError:
                    self._packet_error(
                        "Received checksum {} is not a hexadecimal "
                        "number.".format(checksum))
                    exit_now = True
                    break

                if packet_data_checksum != expected_checksum:
                    self._packet_error(
                        "Checksum validation failed. Checksum of packet data "
                        "is '{}' but received checksum is '{}'.".format(
                            hex(packet_data_checksum),
                            hex(expected_checksum)))
                    exit_now = True
                    break

                # Acknowledge the packet if needed.
                if not self._no_ack_mode:
                    self._send_raw_data(b'+')

                # Process the packet.
                needs_ack = self._process_packet(packet_data)
                if needs_ack:
                    state = self.STATE_ACKNOWLEDGEMENT
                else:
                    state = self.STATE_NEW_PACKET
                packet_data = b''
                checksum = b''

        if self.server.trace:
            _log("Connection closed.")


class GDBServer(socketserver.TCPServer, object):
    """Mock GDB server."""

    allow_reuse_address = True

    def __init__(self, config=None, server_address=('localhost', 0),
                 client_timeout=60, trace=True):
        super(GDBServer, self).__init__(server_address, GDBRequestHandler)
        self.config = config
        self.client_timeout = client_timeout
        self.trace = trace
        self._thread = None

    def serve(self, new_thread=True):
        """
        Start serving client requests.

        If new_thread is True then the server is started in a new thread.
        """

        if self.trace:
            _log("Listening on {}:{}.".format(self.server_address[0],
                                              self.server_address[1]))

        if new_thread:
            self._thread = threading.Thread(target=self._run_server)
            self._thread.start()
        else:
            self._run_server()

    def _run_server(self):
        """Serve client requests until a shutdown is received."""

        self.serve_forever()
        self.server_close()

    def close(self):
        """
        Shutdown the server if it did not exit already and join the listener
        thread if it was started on a new thread.
        """

        self.shutdown()
        if self._thread is not None:
            self._thread.join()


def main():
    """
    Start the mock GDB server on the main thread and make operations on client
    sockets blocking without timeout.
    """

    server = GDBServer(client_timeout=None)
    server.serve(new_thread=False)
    server.close()

if __name__ == '__main__':
    main()
