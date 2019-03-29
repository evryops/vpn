#!/bin/bash
die()
{
	local _ret=$2
	test -n "$_ret" || _ret=1
	test "$_PRINT_HELP" = yes && print_help >&2
	echo "$1" >&2
	exit ${_ret}
}

begins_with_short_option()
{
	local first_option all_short_options
	all_short_options='uph'
	first_option="${1:0:1}"
	test "$all_short_options" = "${all_short_options/$first_option/}" && return 1 || return 0
}



# THE DEFAULTS INITIALIZATION - POSITIONALS
_positionals=()
# THE DEFAULTS INITIALIZATION - OPTIONALS
_arg_user=
_arg_password=

print_help ()
{
	printf '%s\n' "The general script's help msg"
	printf 'Usage: %s [-u|--user <arg>] [-p|--password <arg>] [-h|--help] <server>\n' "$0"
	printf '\t%s\n' "<server>: VPN hostname"
	printf '\t%s\n' "-u,--user: vpn username (no default)"
	printf '\t%s\n' "-p,--password: vpn password (no default)"
	printf '\t%s\n' "-h,--help: Prints help"
}

parse_commandline ()
{
	while test $# -gt 0
	do
		_key="$1"
		case "$_key" in
			-u|--user)
				test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
				_arg_user="$2"
				shift
				;;
			--user=*)
				_arg_user="${_key##--user=}"
				;;
			-u*)
				_arg_user="${_key##-u}"
				;;
			-p|--password)
				test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
				_arg_password="$2"
				shift
				;;
			--password=*)
				_arg_password="${_key##--password=}"
				;;
			-p*)
				_arg_password="${_key##-p}"
				;;
			-h|--help)
				print_help
				exit 0
				;;
			-h*)
				print_help
				exit 0
				;;
			*)
				_positionals+=("$1")
				;;
		esac
		shift
	done
}


handle_passed_args_count ()
{
	_required_args_string="'server'"
	test ${#_positionals[@]} -ge 1 || _PRINT_HELP=yes die "FATAL ERROR: Not enough positional arguments - we require exactly 1 (namely: $_required_args_string), but got only ${#_positionals[@]}." 1
	test ${#_positionals[@]} -le 1 || _PRINT_HELP=yes die "FATAL ERROR: There were spurious positional arguments --- we expect exactly 1 (namely: $_required_args_string), but got ${#_positionals[@]} (the last one was: '${_positionals[*]: -1}')." 1
}

assign_positional_args ()
{
	_positional_names=('_arg_server' )

	for (( ii = 0; ii < ${#_positionals[@]}; ii++))
	do
		eval "${_positional_names[ii]}=\${_positionals[ii]}" || die "Error during argument parsing, possibly an Argbash bug." 1
	done
}

parse_commandline "$@"
handle_passed_args_count
assign_positional_args

# test ! -z $_arg_user || _PRINT_HELP=yes die "FATAL ERROR: user must be defined"
# echo "Value of --user: $_arg_user"
# echo "Value of --password: $_arg_password"
# echo "Value of server: $_arg_server"

export CSD_HOSTNAME="$_arg_server"

OC="/usr/sbin/openconnect -q -b --csd-wrapper="/root/.cisco/csd-wrapper.sh" --no-dtls $_arg_server"
test -z $_arg_user || OC=$OC" -u $_arg_user"
test -z $_arg_password || OC="echo $_arg_password | "$OC" --non-inter --passwd-on-stdin"

echo "Running: $OC"
eval $OC
# Trap user interrupted openconnect
pid=`pidof /usr/sbin/openconnect`
if [ x"$pid" == "x" ]; then
				echo "Exiting..."
				exit 1
fi

let i=0
let ready=0
while [ $i -le 5 ]; do
 ifconfig | grep -q tun0 && ready=1 && break
 sleep 1
 let i++
done
if [ $ready != 1 ]; then
 echo "tun0 didn't appear"
 kill -9 $pid
 exit 1
fi

/usr/sbin/danted -f /etc/danted.conf
kill -9 $pid
exit 0