echo "consumer-service-httpbin.gcp.cx.tetrate.info: `curl -Isk http://20.119.118.153 -H"Host: consumer-service-httpbin.gcp.cx.tetrate.info"  -X GET | grep HTTP`"
echo "external-api-httpbin.gcp.cx.tetrate.info: `curl -Isk http://20.119.118.153 -H"Host: external-api-httpbin.gcp.cx.tetrate.info"  -X GET | grep HTTP`"
echo "rogue-external-api-httpbin.gcp.cx.tetrate.info: `curl -Isk http://20.119.118.153 -H"Host: rogue-external-api-httpbin.gcp.cx.tetrate.info"  -X GET | grep HTTP`"
echo "external-api-httpbin.gcp.cx.tetrate.info: `curl -Isk https://external-api-httpbin.gcp.cx.tetrate.info -H"Host: external-api-httpbin.gcp.cx.tetrate.info" --resolve external-api-httpbin.gcp.cx.tetrate.info:443:20.119.118.153 -X GET | grep HTTP`"
