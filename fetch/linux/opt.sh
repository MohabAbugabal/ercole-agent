#!/bin/sh

# Copyright (c) 2019 Sorint.lab S.p.A.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

SID=$1

if [ -z "$SID" ]; then
  >&2 echo "Missing SID parameter"
  exit 1
fi

DBV=$2

if [ -z "$DBV" ]; then
  >&2 echo "Missing DBV parameter"
  exit 1
fi

HOME=$3

if [ -z "$HOME" ]; then
  >&2 echo "Missing ORACLE_HOME parameter"
  exit 1
fi

LINUX_FETCHERS_DIR=$(dirname "$0")
FETCHERS_DIR="$(dirname "$LINUX_FETCHERS_DIR")"
ERCOLE_HOME="$(dirname "$FETCHERS_DIR")"

export ORAENV_ASK=NO
export ORACLE_SID=$SID
export ORACLE_HOME=$HOME
export PATH=$HOME/bin:$PATH

DB_VERSION=$(
    sqlplus -S / as sysdba <<EOF
set pages 0 feedback off timing off
select (case when UPPER(banner) like '%EXTREME%' then 'EXE' when UPPER(banner) like '%ENTERPRISE%' then 'ENT' else 'STD' end) as versione from v\$version where rownum=1;
exit
EOF
)


if [ $DBV == "10" ] || [ $DBV == "9" ]; then
    sqlplus -S "/ AS SYSDBA" @${ERCOLE_HOME}/sql/opt.sql $CPU_THREADS "$THREAD_FACTOR"
elif [ $DBV == "11" ]; then 
    sqlplus -S "/ AS SYSDBA" @${ERCOLE_HOME}/opt.sql $CPU_THREADS "$THREAD_FACTOR" $DB_ONE
else
IS_PDB=$(
    sqlplus -S / as sysdba <<EOF
set pages 0 feedback off timing off
SELECT CASE WHEN COUNT(*) > 0 THEN 'TRUE' WHEN count(*) = 0 THEN 'FALSE' END FROM v\$pdbs;
exit
EOF
)

if [ $IS_PDB == "TRUE" ]; then
    sqlplus -S "/ AS SYSDBA" @${ERCOLE_HOME}/sql/opt_pluggable.sql $CPU_THREADS "$THREAD_FACTOR" $DB_ONE
else
    sqlplus -S "/ AS SYSDBA" @${ERCOLE_HOME}/sql/opt.sql $CPU_THREADS "$THREAD_FACTOR" $DB_ONE
fi
fi
