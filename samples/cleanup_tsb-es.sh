es_host=tsb-es-http 
es_port=9200 
es_user=elastic 
es_pass=xwls7eaNB4YJN03974wNW821

for tmpl in $(curl -k -u "$es_user:$es_pass" https://$es_host:$es_port/_cat/templates | \
  egrep "alarm_record|browser_|events|log|meter-|metrics-|endpoint_|envoy_|http_access_log|profile_|security_audit_|service_|register_lock|instance_traffic|segment|network_address|top_n|zipkin" | \
  awk '{print $1}'); do curl -k -u "$es_user:$es_pass" https://$es_host:$es_port/_template/$tmpl -XDELETE ; done
  
for idx in $(curl -k -u "$es_user:$es_pass" https://$es_host:$es_port/_cat/indices | \
  egrep "alarm_record|browser_|events|log|meter-|metrics-|endpoint_|envoy_|http_access_log|profile_|security_audit_|service_|register_lock|instance_traffic|segment|network_address|top_n|zipkin" | \
  awk '{print $3}'); do curl -k -u "$es_user:$es_pass" https://$es_host:$es_port/$idx -XDELETE ; done
  
