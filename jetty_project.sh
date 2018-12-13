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

  WAR_FILE=$(find target -type f -name "*.war" -maxdepth 1)

  for IP in ${SERVER_IPS_ARR[@]}
  do
      ssh $IP "pkill -f $PROJECT_UUID" || true
      ssh $IP "
          rm -rf /data/webserver/$PROJECT_UUID
          mkdir -p /data/webserver/$PROJECT_UUID
          cd /data/webserver/$PROJECT_UUID
          java -jar /opt/jetty/start.jar --add-to-startd=http,deploy,jsp,websocket,http-forwarded
      "
      scp $WAR_FILE $IP:/data/webserver/$PROJECT_UUID/webapps/$CONTENT_PATH.war
      ssh $IP "
          cd /data/webserver/$PROJECT_UUID
          mkdir -p /data/webserver/temp
          nohup java -XX:-OmitStackTraceInFastThrow -Djava.io.tmpdir=/data/webserver/temp -jar /opt/jetty/start.jar jetty.port=$JETTY_PORT projectuuid=$PROJECT_UUID > nohup.out 2>&1 &
      "
  done

fi