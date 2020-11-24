MICROSERVICE:=bd_streamer

KC_COMMON_JAR_VERSION:=$(shell bin/extract_kc_common_version_from_pom.sh bd_streamer_dl3/pom.xml)
KC_COMMON_JAR:=${HOME}/.m2/repository/com/kaiostech/kc_common/${KC_COMMON_JAR_VERSION}/kc_common-${KC_COMMON_JAR_VERSION}.jar


VERSION_DOCKER:=$(shell echo -e "{\n\"${MICROSERVICE}\" : {\n \"version\" : \"$$(cat .version)\",\n  \"tag\":\""$$(cat .version)"\"\n}\n}" > bom.json)
GITREF:=$(shell if [ -d .git ]; then git describe --tags --abbrev=9; else echo "none"; fi)

default: ${MICROSERVICE}_dl3

.PHONY: ${MICROSERVICE}_dl3 

all: clean default

${MICROSERVICE}_dl3: ${KC_COMMON_JAR} bd_streamer_dl3/pom.xml
	sh -c 'cd ${MICROSERVICE}_dl3; make'


${KC_COMMON_JAR}: bd_streamer_dl3/pom.xml
	sh -c "./bin/gen_kc_common.sh ${KC_COMMON_JAR_VERSION}"

deploy: clean ${MICROSERVICE}_dl3  ${KC_COMMON_JAR}
	version=`cat .version`; output_folder=${MICROSERVICE}-$${version}; mkdir -p /tmp/$${output_folder}/bin && cp -a  bin/{run3.sh,service_functions.sh,start_service.sh,stop_service.sh,${MICROSERVICE}_dl3-$${version}.jar,functions.sh,jars,conf,run_${MICROSERVICE}_dl3.sh} /tmp/$${output_folder}/bin/ && cp ${KC_COMMON_JAR} /tmp/$${output_folder}/bin/jars/ && mkdir -p /tmp/$${output_folder}/conf/ && cp -a RELEASE.txt /tmp/$${output_folder} && cp -a conf/{${MICROSERVICE}.conf.local,${MICROSERVICE}.conf.k5} /tmp/$${output_folder}/conf/ && tar -jcvf /tmp/${MICROSERVICE}-$${version}.tar.bz2 -C /tmp ${MICROSERVICE}-$${version} && mv /tmp/${MICROSERVICE}-$${version}.tar.bz2 . && rm -Rf /tmp/${MICROSERVICE}-$${version}

docker: ${VERSION_DOCKER}
	@sh -c 'tiller_json=`cat bom.json` tiller -b . –n'
	docker build . -t ${MICROSERVICE}:${GITREF}

ci-container: ${VERSION_DOCKER}
	@sh -c 'tiller_json=`cat bom.json` tiller -b . –n'

doc: bin/gen_doc
	sh -c './bin/gen_doc'
	sh -c 'raml2html kaicloud.raml > ${MICROSERVICE}.html'

test:
	@echo "Testing ${MICROSERVICE}_dl3 ..." && cd ${MICROSERVICE}_dl3 && make test

clean:
	cd ${MICROSERVICE}_dl3 && make clean
	@echo "Deleting generated bom.json file ..." && rm -f bom.json
	@echo "Deleting emacs backup files ..."; find . -type f -name \*~ -exec rm {} \; -print
	@echo "Deleting log files ..."; find . -maxdepth 1 -type f \( -name \*.log.\* -o -name \*.log \) -exec rm {} \; -print
	@echo "Deleting Version information ..."; if [ -d version ]; then rm -Rf version && echo version; fi


clear_cache:
	@echo "Deleting local caches ..."; for cache in ~/go/pkg/mod/cache/download/git.kaiostech.com/cloud/common ~/go/pkg/mod/cache/download/git.kaiostech.com/cloud/thirdparty ~/go/pkg/mod/git.kaiostech.com/cloud ; do if [ -d "$${cache}" ]; then find $${cache} -type f -exec chmod 644 {} \; -print ; find $${cache} -type d -exec chmod 755 {} \; -print ; rm -Rf $${cache} && echo $${cache}; fi; done
