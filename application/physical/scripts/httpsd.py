import http.server
import ssl

httpd = http.server.HTTPServer(
    ('localhost', 4443), http.server.SimpleHTTPRequestHandler)

httpd.socket = ssl.wrap_socket(
    httpd.socket,
    keyfile='../../../data/pki/example.com_intermediate-ca/private-keys/srv2.pem.key',
    certfile='../../../data/pki/example.com_intermediate-ca/public-crts/srv2.pem.crt',
    ca_certs='../../../data/pki/example.com_intermediate-ca/public-crts/example.com_ca-chained-public-crts.pem.crt',
    server_side=True)

httpd.serve_forever()
