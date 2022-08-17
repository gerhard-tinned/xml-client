# The XML client

The XML client is a very simple shell script implementation allowing to interact with a XML API. 

The script allows to define a XML template for each request available via the API. Additionally to the template, a configuration file allows to set parameters for the request. 


## Configuration

A generic configuration file is available in the template directory called "_api.conf". It contains the URL to the API server.

```
XML_URL=http://127.0.0.1:18082/soap
```

## XML template

The XML template contains the XML that will be sent in the requests to the API. All parameters should be replaced with placeholders of the format "#PARAMETERNAME#" (The parameter-name surrounded by '#'). Each line must only contain one parameter placeholder. 

The placeholder name is also the name used as the variable-name to set the value for that parameter. Lines with parameters which are not defined in the request will be removed. 


## CFG files

The config files contain configuration elements for the request.

```
RESULT_FIELDS="nt_user_id"
OK_FIELD_CHECK="nt_user_id"
ERROR_FIELDS="error_code error_desc error_msg"

```

* The RESULT_FIELDS is a space separated list of field names in the XML returned in a success response.
* The OK_FIELD_CHECK is a single field name found in successful a response. If the field is found in the response, the request is considered successful.
* The ERROR_FIELDS is a space separated list of field names in the XML returned in a non-success response. The list of fields is returned when the request was not successful (OK_FIELD_CHECK field not returned).

The success of a request is identified by the presence of the field name specified in the OK_FIELD_CHECK configuration.

## Calling the script 

```
$ ./xml-client.sh -h

Usage: xml-client.sh [-hvd] --tpath /path/to/tmplates/ --request NAME --list VARIABLES
  -h  --help              print this usage and exit
  -v  --version           print version information and exit
  -d                      Enable the debug output
  -t  --tpath DIR         Directory containing the request templates
                          default is the script path subdirectory xml_tmpl
  -r  --request NAME      The name or the request to perform
      --list              List the templates request variables and response variables
                          When given without a request name, the available requests are listed

VARIABLES can be set as environment variables or as arguments in the followiug format
      NAME value          The variables can be passed to the script as arguments
```

In usual XML APIs the first request needed is the authentication request. It is suggested to define the RESULT_FIELDS in a way that it can be used in the requests after. 

```
$ ./xml-client.sh -r login USERNAME root PASSWORD 'Pa55wordUser1'
NT_USER_SESSION 62fbca01a3e613f5
```

When configured in the correct way (like shown above), the resulting field will be the session token required for the requests after the authentication. Sometimes it can be enough to store the output on a variable to be used in following requests.


```
SESSION_TOKEN=$(./xml-client.sh -r login USERNAME root PASSWORD 'Pa55wordUser1')
```


## Showing Request Information

The script allows to list the available request using the "--list" option. 

```
$ ./xml-client.sh --list
login
new_user
verify_session
new_nameserver
get_nameserver
delete_nameserver
get_group_groups
```

Combined with the "-r" option and a request name with the "--list" option, the list of variables in the template are listed as well as the returned Fields from the response.

```
$ ./xml-client.sh --list -r login

# login

## Request Variables
* USERNAME
* PASSWORD

## Response Variables
* NT_USER_SESSION
```

