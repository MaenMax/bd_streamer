artifacts_list:=../bin/META-INF ../bin/com ../bin/conf ../bin/jars ../bin/scripts

VERSION_FILE:=src/main/java/com/kaiostech/version/Version.java
VERSION_DIR:=$(shell dirname ${VERSION_FILE})

default: ${VERSION_FILE}
	sh -c 'mvn package -DskipTests' && mkdir -p target/classes/jars && mvn dependency:copy-dependencies -DoutputDirectory=target/classes/jars && rm -f target/classes/jars/junit* && rm -f target/classes/jars/log4j-slf4j-impl-2.11.0.jar && cp target/bd_streamer_dl3-*.jar ../bin && cp target/classes/scripts/* ../bin && chmod 755 ../bin/*.sh && cp -r target/classes/jars ../bin && mkdir -p ../bin/conf && cp src/main/resources/conf/log4j2.xml ../bin/conf/log4j2-dl3.xml

${VERSION_FILE}: ../.version ../bin/gen_version_java.sh
	mkdir -p ${VERSION_DIR} && ../bin/gen_version_java.sh ../.version >$@

clean:
	@sh -c 'mvn clean'
	@echo "Deleting following files/folders ..."
	@for i in ${artifacts_list}; do if [ -e $$i ]; then rm -Rf $$i && echo $$i; fi; done
	@rm -f ../bin/bd_streamer_dl3-*.jar && echo ../bin/bd_streamer_dl3-*.jar
	@for i in `ls src/main/resources/scripts/* | sed 's/src\/main\/resources\/scripts\///g'`; do script_name=$$i; if [ -f ../bin/$$script_name ]; then rm -f ../bin/$$script_name && echo ../bin/$$script_name; fi; done
	@rm -Rf ${VERSION_DIR} && echo ${VERSION_DIR}

test: ${VERSION_FILE}
	@echo "========== TESTING DL3 =========="
	@sh -c 'mvn clean test -e || echo "Failed"' 
# add -Dtest=TestClassName to only execute one class
all: ${VERSION_FILE}
	sh -c 'mvn package' && cp target/bd_streamer_dl3-*.jar ../bin && cp target/classes/scripts/* ../bin && chmod 755 ../bin/*.sh && cp -r target/classes/jars ../bin && mkdir -p ../bin/conf && cp src/main/resources/conf/log4j2.xml ../bin/conf/log4j2-dl3.xml
