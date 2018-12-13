PROJECT_UUID=${JOB_NAME##*/}
SERVER_IPS_ARR=(${SERVER_IPS//,/ })

if [ "$EVENT" = "kill" ]; then

  for IP in ${SERVER_IPS_ARR[@]}
  do
      ssh $IP "pkill -f $PROJECT_UUID" || true
  done

else

  if [ "$MVN_PROFILE" = "" ]; then
      mvn clean package -Dmaven.test.skip=true
  else
      mvn clean package -Dmaven.test.skip=true -P$MVN_PROFILE
  fi


  JAR_FILE=$(find target -type f -name "*.jar" -maxdepth 1 -exec du '{}' \; | sort -nrk 1 | head -n 1 | cut -f 2)


  for IP in ${SERVER_IPS_ARR[@]}
  do
      ssh $IP "pkill -f $PROJECT_UUID" || true
      ssh $IP "
          rm -rf /data/webserver/$PROJECT_UUID
          mkdir -p /data/webserver/$PROJECT_UUID
      "
      scp $JAR_FILE $IP:/data/webserver/$PROJECT_UUID/root.jar
      ssh $IP "
          cd /data/webserver/$PROJECT_UUID
          nohup java -XX:-OmitStackTraceInFastThrow -jar /data/webserver/$PROJECT_UUID/root.jar > nohup.out 2>&1 &
      "
  done

fi