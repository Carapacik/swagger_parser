# Schema download fixtures

JSON/YAML pairs cover origins, headers, environment references, and input batches.
PORT_A, PORT_B, and EXT are replaced with local test values.
The TLS test uses OpenSSL to create a temporary certificate and private key.
Test teardown deletes both files. The client pins the certificate to its
loopback host and port. CLI TLS verification stays enabled.
