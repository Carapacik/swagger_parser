# Binary response contracts

Paired JSON and block YAML cover Swagger 2.0 and OpenAPI 3.0, 3.1, and 3.2.
Related PDF, XLSX, octet-stream, and metadata routes share each document.
Swagger uses type: file; OpenAPI uses type: string with format: binary.

- `report.pdf`: a one-page PDF with a non-ASCII binary marker.
- `sheet.xlsx`: an XLSX workbook with cell A1 set to 42.
- `arbitrary.bin`: every byte value from 0 through 255.

Compare exact bytes in buffered and stream modes. Check empty bodies, partial
reads, cancellation, source failures, and original response wrappers. Modern
schemas also describe a JSON error beside binary success. Swagger uses its
operation-wide produces declaration and a bodyless 204.

The network driver holds the second half of a PDF until the test releases it.
VM clients and package:http on Chrome must expose the first half before release.
Dio's standard web adapter buffers XHR responses; check complete bytes there.
