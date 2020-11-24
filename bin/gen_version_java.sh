#!/bin/sh

if [ "x" = "x$1" ]; then
    echo >&2 "Missing version argument from .version file! Aborting ..."
    exit 1
fi

version=`cat "$1"`
thedate=`date +"%Y%m%d%H%M%S"`
commit_id=`git log --pretty=oneline | head -1 | awk '{ print $1 }'`
buildid="${commit_id}-${thedate}"
build_date=`date`
builder=`whoami`
hostname=`hostname`
kernel_version=`uname -a`
kernel_release=`cat /etc/redhat-release`

cat <<EOF
package com.kaiostech.version;

import java.lang.StringBuilder;

public class Version {
    public static String VERSION = "$version";
    public static String BUILDID = "$buildid";
    public static String DATE = "$build_date";
    public static String BUILDER = "$builder";
    public static String HOSTNAME = "$hostname";
    public static String KERNEL_VERSION = "$kernel_version";
    public static String KERNEL_RELEASE = "$kernel_release";

    public static String Get_Version() {
        return VERSION;
    }

    public static String Get_BuildID()  {
       return BUILDID;
    }

    public static String Get_Build_Date() {
       return DATE;
    }

    public static String Get_Builder() {
       return BUILDER;
    }

    public static String Get_Hostname() {
       return HOSTNAME;
    }

    public static String getFullVersion() {
       StringBuilder buffer;
       buffer = new StringBuilder();
 
       buffer.append("        Version: ").append(VERSION).append("\n");
       buffer.append("       Build ID: ").append(BUILDID).append("\n");
       buffer.append("     Build Date: ").append(DATE).append("\n");
       buffer.append("        Builder: ").append(BUILDER).append("\n");
       buffer.append("     Build Host: ").append(HOSTNAME).append("\n");
       buffer.append(" Kernel Version: ").append(KERNEL_VERSION).append("\n");
       buffer.append(" Kernel Release: ").append(KERNEL_RELEASE).append("\n");
       buffer.append("\n");

       return buffer.toString();
    }
    
}


EOF
