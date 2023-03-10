FILE_TMP=/tmp/data.$$.tmp

ESHOST=localhost:19200

docker exec -it mysql mysql -u myuser -prootpass -e "select status, filename, records from info_files where status = 'PENDING' and ts_insert <  date_sub(sysdate(), interval 1 minute) ;" mydatabase | grep PENDING | sed -e "s/ //g"   > $FILE_TMP

echo  DATA TO CHECK ---------------------------------------------
cat $FILE_TMP
echo -----------------------------------------------------------
echo

for LINE in $(cat $FILE_TMP)
do
  DATAFILE=$(echo $LINE | awk -F "|" '{ print $3}' )
  NUM_RECS=$(echo $LINE | awk -F "|" '{ print $4}' )
#  echo $DATAFILE "-" $NUM_REGS

  NUM_RECS_IN_ES=$(curl -s "$ESHOST/index-data/_search?pretty&size=0&track_total_hits=true&q=filename:$DATAFILE" | grep total -A1 | tail -1 | sed -e "s/,//g" | awk '{ print $NF ;}')
  SUM_LINES_IN_ES=$(
  curl -s -H 'Content-Type: application/json' -XPOST "$ESHOST/index-data/_search?pretty&size=0&track_total_hits=true" -d "
{ \"query\": { \"bool\": { \"must\": [{\"match_phrase\": { \"filename\": \"$DATAFILE\"}}]}
  },\"aggs\": { \"sum_num_lines\": {\"sum\": {\"field\": \"line_number\"}}}
}" | grep sum_num_lines -A1 | tail -1 | sed -e "s/,//g" | awk '{ print $NF ;}'

)

#  echo -${NUM_RECS_IN_ES}-
#  echo -${SUM_LINES_IN_ES}-

  if [ "$NUM_RECS_IN_ES" == "" ] ; then NUM_RECS_IN_ES=0 ; fi
  if [ "$SUM_LINES_IN_ES" == "" ] ; then SUM_LINES_IN_ES=0 ; fi

  STATUS=OK
  if [ "$NUM_RECS" -ne "$NUM_RECS_IN_ES" ]; then
          STATUS=KO ;
  else
          RES_CHECK_SUM=$(echo ${SUM_LINES_IN_ES} ${NUM_RECS_IN_ES} | awk '{ if ( $1-$2*($2+1)/2 == 0) print "OK"; else print "KO" }' )
  fi


  QUERY_UPD="update info_files set status = '$STATUS',  records_es = $NUM_RECS_IN_ES, sum_lines_records_es=${SUM_LINES_IN_ES}, ts_check = sysdate() where filename = '$DATAFILE'"

#  echo $QUERY_UPD

  docker exec -it mysql mysql -u myuser -prootpass -e "$QUERY_UPD" mydatabase 2>/dev/null

done

echo Actual data -----------------------------------------------------------------
docker exec -it mysql mysql -u myuser -prootpass -e "select * from info_files order by ts_insert desc" mydatabase 2>/dev/null

rm $FILE_TMP

