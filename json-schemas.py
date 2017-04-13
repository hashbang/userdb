#!/usr/bin/env python
import string, yaml, json

with open('json-schemas.sql', 'r') as in_file:
    data = in_file.read()

for name in ('user', 'host'):
    with open("schemas/data_%s.yml" % name, 'r') as schema:
        json_data = json.dumps(yaml.load(schema))
        data = string.replace(data, '{data_%s}' % name, json_data)

with open('json-schemas.sql.tmp', 'w') as outfile:
    outfile.write(data)
