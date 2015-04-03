#!/bin/bash
# patch.sh by @nieltg

# Patches format: [BASE]-[NAME].patch
# [BASE]: base repo, ex: "frameworks/av" => "frameworks-av" ('/' => '-')
# [NAME]: patch title, ex: "Audio Patch" => "Audio-Patch" (' ' => '-')

# TODO:
# - Reorganize logging mechanism.
#   pa_out_prog() & pa_out_stat() which are more high-level should also
#   take care of file logging mechanism.
# - Add argument parser to support these features:
#   clean: call 'git checkout . ; git clean -f' in every patched repos.
#   dry-run: 'patch --dry-run'. Warning: see NOTE before pa_patch_awk()
#   reverse: reverse applied patches using 'patch -R'. (is-important?)
#   walk: every patches: clean repo, apply, 'git diff' & save new patch.
# - Reorganize patches.
#   Use '[BASE]/[NAME].patch' (patches inside 1st level directories)
#   instead of using '[BASE]-[NAME].patch'.
# - Show 'SKIP' for applied patches. (instead of 'FAIL')
#   Modify awk script to recognize if a patch has been applied before.

PA_APP=$(basename "${BASH_SOURCE[0]}")

# == Function Definitions ==

pa_err ()
{
	echo "$@" > /dev/stderr
}

pa_log ()
{
	echo "$@" >> "${PA_LOG}"
}

pa_out_prog ()
{
	pa_err -n "Applying ${1}... "
}

if [ -t 1 ] ; then
	
	# Interactive shell.
	
	pa_out_stat ()
	{
		local clr='\r\e[K'
		local rst='\e[0m'
		local col=
		local out=
		
		case ${2} in
		PASS)
			col='\e[0;32m'
			;;
		SKIP)
			col='\e[0;33m'
			;;
		FAIL)
			col='\e[0;31m'
			;;
		esac
		
		if [ -n "${3}" ] ; then 
			out="${1} (${3})"
		else
			out="${1}"
		fi
		
		pa_err -en "${clr}${col}[$2]${rst} "
		pa_err "${out}"
	}
	
else
	
	# Non-interactive shell.
	
	pa_out_stat ()
	{
		pa_err "${2} (${3})"
	}
	
fi

pa_out_rej ()
{
	if [ $# -le 0 ] ; then
		return
	fi
	
	pa_err "Rejected patches:"
	
	for rej in "$@" ; do
		pa_err "  ${rej}"
	done
	
	pa_err
}

pa_out_fin ()
{
	pa_err "Patching completed! (full: ${1}, part: ${2}, skip: ${3})"
}

pa_parse_path ()
{
	local a="${1%%_*}"
	echo "${a//-//}"
}

pa_parse_capt ()
{
	local a="${1#*_}"
	local b="${a%.patch}"
	echo "${b//-/ }"
}

# NOTE:
# Instead of "patching file", 'patch --dry-run' writes "checking file".
# So, we have to modify the awk script to parse 'patch --dry-run' log.

pa_patch_awk ()
{
	awk 'BEGIN {
		relc_c = 0
		fail_c = 0
	}
	{
		if ( $1 == "PATCHSH_CDFAIL" ) {
			cdfail = 1
			exit 0
		} else if ( $1 == "PATCHSH_RETVAL" ) {
			retval = $2
			exit 0
		} else if ( ($1 $2) == ("patching" "file") ) {
			cf = $3
		} else if ( $1 == "Hunk" ) {
			if ( ($3 $4) == ("succeeded" "at") ) { relc_c++ }
			else if ( $3 == "FAILED" ) { fail_c++ ; fail_r[cf] = 0 }
		}
	}
	END {
		if ( cdfail == 1 ) {
			print "local AWK_CDFAIL=1"
		} else {
			print "local AWK_RELC_C=" relc_c
			print "local AWK_FAIL_C=" fail_c
			fr = "local AWK_FAIL_R=("
			for ( r in fail_r ) { fr = fr "\"" r ".rej\" " }
			print fr ")"
			print "local AWK_RETVAL=" retval
		}
	}'
}

pa_patch_keep ()
{
	eval $(pa_patch_awk)
	
	if [ -n "${AWK_CDFAIL}" ] ; then
		# Put global vars!
		pa_o_desc="cd fail"
		pa_o_mode=SKIP
		
		return
	fi
	
	local a=""
	local b="FAIL"
	
	if [ ${AWK_RELC_C} -ne 0 ] ; then
		a+="${AWK_RELC_C} reloc"
	fi
	
	if [ ${AWK_FAIL_C} -ne 0 ] ; then
		if [ -n "${a}" ] ; then a+=", " ; fi
		a+="${AWK_FAIL_C} rej"
	fi
	
	if [ ${AWK_RETVAL} -eq 0 ] ; then
		b="PASS"
	fi
	
	# Put global vars!
	
	pa_o_rejc=("${AWK_FAIL_R[@]}")
	pa_o_desc="${a}"
	pa_o_mode="${b}"
}

# == Main Program ==

pa_err "${PA_APP} by @nieltg"
pa_err

if [ -z "${ANDROID_BUILD_TOP}" ] ; then
	pa_err "${PA_APP}: \${ANDROID_BUILD_TOP} is not defined"
	pa_err "${PA_APP}: build/envsetup.sh should be executed first!"
	pa_err
	exit 1
fi

PA_P_PATH="$(dirname "${BASH_SOURCE[0]}")"
PA_P_REAL="$(realpath "${PA_P_PATH}")"

pa_err "Build top: ${ANDROID_BUILD_TOP}"
pa_err "Patch dir: ${PA_P_PATH}"
pa_err

cd "${ANDROID_BUILD_TOP}"

mv -f patch.log patch.log.old > /dev/null 2>&1
touch patch.log

PA_LOG="$(realpath patch.log)"

pa_log "${PA_APP} by @nieltg"
pa_log $(date)
pa_log
pa_log

cd "${PA_P_REAL}"

pa_s_rejc=()
pa_s_PASS=0 ; pa_s_SKIP=0 ; pa_s_FAIL=0

for pa in *.patch ; do
	
	pa_ds0="$(pa_parse_path "${pa}")" ; pa_dst="${ANDROID_BUILD_TOP}/${pa_ds0}"
	pa_src="$(realpath "${pa}")" ; pa_cap="(${pa_ds0}) $(pa_parse_capt "${pa}")"
	
	pa_log "PATCH: ${pa_cap}"
	pa_log
	
	pa_out_prog "${pa_cap}"
	
	#if ! [ -d "${pa_dst}" ] ; then
	#	pa_out_stat "${pa_cap}" SKIP "no directory"
	#	continue
	#fi
	
	# ( cd "${pa_dst}" ; if [ $? -ne 0 ] ; then exit 1 ; fi
	#   patch -p1 --dry-run < "${pa_src}" 2>&1 ) | pa_patch_pipe >(pa_patch_keep)
	
	pa_patch_keep < <(
		cd "${pa_dst}" > /dev/null 2>&1
		if [ $? -ne 0 ] ; then
			echo "PATCHSH_CDFAIL"
			exit 1
		fi
		patch -p1 < "${pa_src}" 2>&1 | tee -a "${PA_LOG}"
		echo "PATCHSH_RETVAL ${PIPESTATUS[0]}"
	)
	
	for rej in "${pa_o_rejc[@]}" ; do
		pa_s_rejc=("${pa_s_rejc[@]}" "(${pa_ds0}) ${rej}")
	done
	
	if echo ${pa_o_mode} | grep -q -e "PASS" -e "SKIP" -e "FAIL" ; then
		let "pa_s_${pa_o_mode}++"
	fi
	
	pa_log
	pa_log "STATUS: ${pa_o_mode} (${pa_o_desc})"
	pa_log
	
	pa_out_stat "${pa_cap}" "${pa_o_mode}" "${pa_o_desc}"
	
done

pa_err ; pa_log

{
	pa_out_rej "${pa_s_rejc[@]}"
	pa_out_fin "${pa_s_PASS}" "${pa_s_FAIL}" "${pa_s_SKIP}"
} 2>&1 | tee -a "${PA_LOG}" 1>&2

pa_err

