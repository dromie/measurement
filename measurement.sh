#!/bin/bash
#DATE,DAYTOTAL,LASTCONNECTTOTAL
DATA=/mnt/usb/graph/measurement.txt
IFACE=ppp0
HEADER="Date,CurrentTotal,SubTotal,DailyTotal"
if [ -f /mnt/usb/USB_DISK_NOT_PRESENT ]; then 
	exit -1
fi

calculate() {
  DATE=$1
  TOTAL=$2
  PREVDATE=${3:-""}
  PREVTOTAL=${4:-0}
  LASTCT=${5:-0}
  if [ $PREVDATE == $DATE ];then
    if [ $PREVTOTAL -gt $TOTAL ]; then
      let LASTCT=$LASTCT+$PREVTOTAL
    fi
  else
    if [ $TOTAL -ge $PREVTOTAL ]; then
      let LASTCT=-$PREVTOTAL
    else
      LASTCT=0
    fi
  fi
  let DAYTOTAL=$LASTCT+$TOTAL
  echo "$DATE,$TOTAL,$LASTCT,$DAYTOTAL"
}


test() {
 #echo "DATE: $1 TOTAL: $2 PREVDATE:$3 PREVTOTAL: $4 LASTCT: $5"
 #echo "DATE,TOTAL,LASTCT,DAYTOTAL"
 calculate $@
 echo
}

log() {
DEBUGDATE=`date`
echo "$DEBUGDATE $*" >>$DATA.debug
}

if [ "$1" == "test" ];then
  shift
  test $@
  exit 0
fi

if ! ifconfig $IFACE &>/dev/null;then
	log "$IFACE Not found"
	exit 1
fi


RX=`ifconfig $IFACE|grep 'TX bytes'|sed 's/.*RX bytes:\([0-9]*\).*/\1/'`
TX=`ifconfig $IFACE|grep 'TX bytes'|sed 's/.*TX bytes:\([0-9]*\).*/\1/'`
DATE=`date "+%Y-%m-%d"`
if [ ! -w $DATA ];then
 echo $HEADER >$DATA
fi
PREV=`grep -v "$HEADER" $DATA|tail -1`
let TOTAL=$RX+$TX
LASTCT=0
PREVDATE=$DATE
PREVTOTAL=0
if [ -n "$PREV" ]; then
  PREVDATE=`echo $PREV|awk -F, '{print $1}'`
  PREVTOTAL=`echo $PREV|awk -F, '{print $2}'`
  LASTCT=`echo $PREV|awk -F, '{print $3}'`
fi
CALCULATED=`calculate $DATE $TOTAL $PREVDATE $PREVTOTAL $LASTCT`
log "$DATE $TOTAL $PREVDATE $PREVTOTAL $LASTCT $CALCULATED"
grep -v "^$DATE" $DATA >$DATA.tmp
echo $CALCULATED >>$DATA.tmp
mv $DATA.tmp $DATA

