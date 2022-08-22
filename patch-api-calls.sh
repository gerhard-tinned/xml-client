#!/bin/bash
# 
VERSION="0.1.2"
#

###############################################################################
# Configuration

SCRIPT_CMD="./xml-client.sh"
AUTH_REQUEST="login"
AUTH_VARS="USERNAME PASSWORD"

###############################################################################


function help_screen () {
    for V in ${AUTH_VARS}; do
        VL="${VL} ${V} \"value for ${V}\""
    done
    echo 
    echo "Usage: $(basename $0) [-hv] ${VL}"
    echo "  -h  --help              print this usage and exit"
    echo "  -v  --version           print version information and exit"
    echo "  -d                      Enable the debug output"
    echo "      --log /path/        Use the provided a directory for log files (one log file per request)"
    echo "      --csv FILE.csv      Use the provided filename as list of API calls to perform"
    echo ""
    echo "VARIABLES can be set as environment variables or as arguments in the followiug format"
    echo "      NAME value          The variables can be passed to the script as arguments "
}

function errorout () {
    echo -e "$@" >&2
}

function echoout () {
    echo -e "$@"
}

function formatout () {
    FORMATOUT_FORMAT=$1
    shift
    printf "${FORMATOUT_FORMAT}" $@
}

function debugout () {
    # Send debug output when debug mode is enabled
    if [[ ${DEBUG} != 0 ]]; then
        if [[ "${LOG_PATH}" == "" ]]; then
            echo -e "$(date "+%F %T") - $@" >&2
        else
            echo -e "$(date "+%F %T") - $@" | tee -a ${LOG_PATH}/csv_request_${REQUEST_COUNT}.log >&2
        fi
    fi
}

OSTYPE=$(uname -s)

DEBUG=0
DEBUG_CMD=''
LOG_PATH=""
while [ $# -gt 0 ]; do
    case $1 in
        # General parameter
        -h|--help)
            help_screen
            exit 0
            ;;

        -v|--version)
            echo 
            echo "`basename $0` version ${VERSION}"
            echo
            exit 0
            ;;

        -d)
            DEBUG=1
            DEBUG_CMD="-d"
            shift 1
            ;;

        --log)
            if [[ ! -z "$2" ]] && [[ -d "$2" ]]; then
                DEBUG=1
                DEBUG_CMD="-d"
                LOG_PATH=$2
                TEMP_FILE=$(mktemp)
            else
                echo "ERROR: Specified log path does not exist."
                help_screen
                exit 1
            fi
            shift 2
            ;;

        --csv)
            if [[ ! -z "$2" ]] && [[ -f "$2" ]]; then
                CSV_FILE=$2
            else
                echo "ERROR: Specified csv file does not exist."
                help_screen
                exit 1
            fi
            shift 2
            ;;

        # VARIABLES        
        *)
            if [[ "${1}" == "$(echo ${1} | egrep '^[A-Z_]+$')" ]] && [[ ! -z "$2" ]]; then
                export PAC_${1}="${2}"
                shift 2
            else
                echo "ERROR: Unknown option '$1'"
                help_screen
                exit 1
                break
            fi
            ;;
    esac
done


for V in ${AUTH_VARS}; do
    VN="PAC_$V"
    if [[ -z "${!VN}" ]]; then
        errorout "Missing variable $V"
        exit 1
    fi
done

if [[ -z "${CSV_FILE}" ]]; then
    errorout "Missing --csv option."
    exit 1
fi

###############################################################################
# 
###############################################################################

REQUEST_COUNT=0


# Authenticate
echoout "# Authenticate ..."
for V in ${AUTH_VARS}; do
    VN="PAC_$V"
    VL="${VL} ${V} '${!VN}'"
done
debugout "${SCRIPT_CMD} ${DEBUG} -r ${AUTH_REQUEST} ${VL}"
if [[ "${LOG_PATH}" == "" ]]; then
    AUTH_TOKEN=$(echo ${SCRIPT_CMD} ${DEBUG_CMD} -r ${AUTH_REQUEST} ${VL} | bash)
else
    AUTH_TOKEN=$(echo ${SCRIPT_CMD} ${DEBUG_CMD} -r ${AUTH_REQUEST} ${VL} | bash 2>${TEMP_FILE})
    debugout "$(cat ${TEMP_FILE})"
fi
debugout "Authentication: ${AUTH_TOKEN}"

((REQUEST_COUNT++))


CMD_VARS=$(sed -e 's/ *; */;/g' -e 's/ *$//' ${CSV_FILE} |awk -F\; '
/^#/ {next}
/^\s*$/ {next}
BEGIN   {
    getline
    for (i=1;i<=NF;i++)
        CNAME[i]=$i
    }

    {
    for (i=1;i<=NF;i++)
        {
        VAL[CNAME[i]]=$i
        if ($i == "")
            delete VAL[CNAME[i]]
        }

    printf("%s ", VAL["API_REQUEST"])
    delete VAL["API_REQUEST"]
    for (FIELD in VAL)
        printf("%s \"%s\" ",FIELD, VAL[FIELD])
    printf("\n")
    }')

echoout "# Execute API calls ..."
echo "${CMD_VARS}" | while read VARS; do
    echoout "${REQUEST_COUNT} - Executing $(echo ${VARS} | awk '{print $1}')"
    debugout "${REQUEST_COUNT} - ${SCRIPT_CMD} ${DEBUG_CMD} -r ${VARS} ${AUTH_TOKEN}"
    if [[ "${LOG_PATH}" == "" ]]; then
        debugout "$(echo ${SCRIPT_CMD} ${DEBUG_CMD} -r ${VARS} ${AUTH_TOKEN} | bash)"
    else
        debugout "$(echo ${SCRIPT_CMD} ${DEBUG_CMD} -r ${VARS} ${AUTH_TOKEN} | bash 2>&1)"
    fi
    ((REQUEST_COUNT++))
done

exit
