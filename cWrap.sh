BASE_DIR=/data/unified/WmAgentScripts/

HTML_DIR=/data/unified/www
FINAL_HTML_DIR=/eos/cms/store/unified/www/

if [ ! -d $FINAL_HTML_DIR ] ; then 
    echo "Cannot read the log destination",$FINAL_HTML_DIR
    exit
fi
cd $BASE_DIR

modulename=`echo $1 | sed 's/\.py//' | sed 's/Unified\///'`
mkdir -p $HTML_DIR/logs/$modulename/
mkdir -p $FINAL_HTML_DIR/logs/$modulename/

last_log=$HTML_DIR/logs/$modulename/last.log
dated_log=$HTML_DIR/logs/$modulename/`date +%F_%T`.log
log=$dated_log

echo `date` > $log
echo $$ >> $log

if [ -r unified_drain ] ; then
    echo "System is locally draining" >> $log
    cp $log $last_log
    cp $log $FINAL_HTML_DIR/logs/$modulename/.
    cp $log $FINAL_HTML_DIR/logs/$modulename/last.log
    exit
fi
if [ -r /eos/cms/store/unified/unified_drain ] ; then
    echo "System is globally draining" >> $log
    cp $log $last_log
    cp $log $FINAL_HTML_DIR/logs/$modulename/.
    cp $log $FINAL_HTML_DIR/logs/$modulename/last.log
    exit
fi


echo $USER >> $log
echo $HOSTNAME >> $log
echo module $modulename>> $log 

echo $PWD
ls set.sh
source set.sh
##source $BASE_DIR/set.sh

echo >> $log

start=`date +%s`
python ssi.py $modulename $start

python $* &>> $log

if [ $? == 0 ]; then
    echo "finished" >> $log
else
    emaillog=$log.log
    failed_pid=$!
    echo -e "\nAbnormal termination with exit code $?" >> $log
    top -n1  -o %MEM -c >> $log
    echo "Abnormal termination, check $log" > $emaillog
    echo $failed_pid >> $emaillog
    echo $USER >> $emaillog
    echo $HOSTNAME >> $emaillog
    echo module $modulename>> $emaillog 
    mail -s "[Ops] module "$modulename" failed" -a $emaillog cmsunified@cern.ch
fi

stop=`date +%s`
python ssi.py $modulename $start $stop
echo `date` >> $log

#cp $log $dated_log
cp $log $last_log
cp $log $FINAL_HTML_DIR/logs/$modulename/.
cp $log $FINAL_HTML_DIR/logs/$modulename/last.log

#rm $log
