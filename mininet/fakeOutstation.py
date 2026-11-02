#!/usr/bin/python           # This is server.py file

import socket               # Import socket module
import struct
import binascii
import errno
from socket import error as socket_error

#mValue = {11: 1.00}

#reqLength = 2 + len(mValue.keys())
#reqFormat = 'B' * reqLength

#resLength = 2 + 5*len(mValue.keys())

if __name__ == "__main__":

    s = socket.socket()         # Create a socket object
    s1 = socket.socket()
    relayIP = '10.0.0.1'
    #host = socket.gethostname() # Get local machine name
    #host = '127.0.0.1'
    host = '10.0.0.2'
    port = 20000                # Reserve a port for your service.

    print 'Bind'
    s.bind((host, port))        # Bind to the port

    print 'listen'
    s.listen(5)                 # Now wait for client connection.

    while True:
        c, addr = s.accept()     # Establish connection with client.
        print 'DEBUG: Got connection from', addr

        try:
            #relayS[i].connect((host, port + i+ 1))
            s1.connect((relayIP, port))
        except socket_error as serr:
            print serr
            s1.close()

        #print 'DEBUG active relay:', ActiveRelay

        i=0
        while True:

            req = c.recv(1024)
            #print 'DEBUG req: ', binascii.hexlify(req), len(req)

            if len(req) == 0:
                continue;

            s1.send(req)

            transport = 0;
            while transport == 0:
                res = s1.recv(1024)
                print 'DEBUG res: ', binascii.hexlify(res), len(res)
                simpleFormat = '=' + 'B' * len(res)
                resUnpacked = struct.Struct(simpleFormat).unpack(res)
                transport = resUnpacked[10] & 0b10000000
                c.send(res)
            #res = s1.recv(1024)
            #c.send(res)
          
         
        #c.send('Thank you for connecting')
        c.close()                # Close the connection
        s1.close()

