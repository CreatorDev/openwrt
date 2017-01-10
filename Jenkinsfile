#!/usr/bin/env groovy

/**
 * Build openwrt project
 *
 * Configure as needed, pull in the feeds and run the build. Allows
 * overridding feeds listed using build parameters.
 * 
 * Note this script needs some extra Jenkins permissions to be
 * approved.
 */
// TODO be careful with using dir() until JENKINS-33510 is fixed

def customFeeds = [
    ['packages', 'packages', 'https://github.com/CreatorDev'],
    ['ci40', 'ci40-platform-feed', 'https://github.com/CreatorDev'],
]
def feedParams = []
for (feed in customFeeds) {
    feedParams.add(string(defaultValue: '', description: 'Branch/commmit/PR to override feed. \
        (Can be a PR using PR-< id >)', name: "OVERRIDE_${feed[0].toUpperCase()}"))
}

properties([
    buildDiscarder(logRotator(numToKeepStr: '5')),
    parameters([
        booleanParam(defaultValue: false,
            description: 'Build extra tools such as toolchain, SDK and Image builder',
            name: 'BUILD_TOOLS'),
        booleanParam(defaultValue: false, description: 'Build *all* packages for opkg',
            name: 'ALL_PACKAGES'),
        stringParam(defaultValue: 'target/linux/pistachio/creator-platform-default-cascoda.config',
            description: 'Config file to use', name: "CONFIG_FILE"),
        stringParam(defaultValue: '', description: 'Set version, if blank job number will be used.',
            name: 'VERSION'),
        stringParam(defaultValue: '',
            description: 'Branch to use for Boardfarm',
            name: 'OVERRIDE_BOARDFARM'),
    ] + feedParams)
])

node('docker && imgtec') {  // Only run on internal slaves as build takes a lot of resources
    def docker_image

    stage('Prepare Docker container') {
        // Setup a local docker container to run build on this slave
        docker_image = docker.image "imgtec/creator-builder:latest" // TODO for now have manually setup on slave
    }

    docker_image.inside("-v ${WORKSPACE}/../../reference-repos:${WORKSPACE}/../../reference-repos:ro") {
        stage('Configure') {
            // Checkout a clean version of the repo using reference repo to save bandwidth/time
            checkout([$class: 'GitSCM',
                userRemoteConfigs: scm.userRemoteConfigs,
                branches: scm.branches,
                doGenerateSubmoduleConfigurations: scm.doGenerateSubmoduleConfigurations,
                submoduleCfg: scm.submoduleCfg,
                browser: scm.browser,
                gitTool: scm.gitTool,
                extensions: scm.extensions + [
                    [$class: 'CleanCheckout'],
                    [$class: 'PruneStaleBranch'],
                    [$class: 'CloneOption', honorRefspec: true, reference: "${WORKSPACE}/../../reference-repos/openwrt.git"],
                ],
            ])

            // Versioning
            sh "echo ${params.VERSION?.trim() ?: 'j' + env.BUILD_NUMBER} > version"

            // Default config
            sh "cp ${params.CONFIG_FILE?.trim()} .config"

            // Add development config
            echo 'Enabling development config'
            sh 'echo \'' \
             + 'CONFIG_DEVEL=y\n' \
             + 'CONFIG_LOCALMIRROR=\"https://downloads.creatordev.io/pistachio/marduk/dl\"\n' \
             + '\' >> .config'

            // Build tools/sdks
            if (params.BUILD_TOOLS) {
                echo 'Enabling toolchain, image builder and sdk creation'
                sh 'echo \'' \
                 + 'CONFIG_MAKE_TOOLCHAIN=y\n' \
                 + 'CONFIG_IB=y\n' \
                 + 'CONFIG_SDK=y\n' \
                 + '\' >> .config'
            }

            // Build all (for opkg)
            if (params.ALL_PACKAGES){
                echo 'Enabling all user and kernel packages'
                sh 'echo \'' \
                 + 'CONFIG_ALL=y\n' \
                 + '\' >> .config'
            }

            // Boardfarm-able
            // TODO work out which ones we actually have
            echo 'Enabling usb ethernet adapters modules (for boardfarm testing)'
            sh 'echo \'' \
             + 'CONFIG_PACKAGE_kmod-usb-net=y\n' \
             + 'CONFIG_PACKAGE_kmod-usb-net-asix=y\n' \
             + 'CONFIG_PACKAGE_kmod-usb-net-cdc-eem=y\n' \
             + 'CONFIG_PACKAGE_kmod-usb-net-cdc-ether=y\n' \
             + 'CONFIG_PACKAGE_kmod-usb-net-cdc-mbim=y\n' \
             + 'CONFIG_PACKAGE_kmod-usb-net-cdc-ncm=y\n' \
             + 'CONFIG_PACKAGE_kmod-usb-net-cdc-subset=y\n' \
             + 'CONFIG_PACKAGE_kmod-usb-net-dm9601-ether=y\n' \
             + 'CONFIG_PACKAGE_kmod-usb-net-hso=y\n' \
             + 'CONFIG_PACKAGE_kmod-usb-net-huawei-cdc-ncm=y\n' \
             + 'CONFIG_PACKAGE_kmod-usb-net-ipheth=y\n' \
             + 'CONFIG_PACKAGE_kmod-usb-net-kalmia=y\n' \
             + 'CONFIG_PACKAGE_kmod-usb-net-kaweth=y\n' \
             + 'CONFIG_PACKAGE_kmod-usb-net-mcs7830=y\n' \
             + 'CONFIG_PACKAGE_kmod-usb-net-pegasus=y\n' \
             + 'CONFIG_PACKAGE_kmod-usb-net-qmi-wwa=y\n' \
             + 'CONFIG_PACKAGE_kmod-usb-net-rndis=y\n' \
             + 'CONFIG_PACKAGE_kmod-usb-net-rtl8150=y\n' \
             + 'CONFIG_PACKAGE_kmod-usb-net-rtl8152=y\n' \
             + 'CONFIG_PACKAGE_kmod-usb-net-sierrawireless=y\n' \
             + 'CONFIG_PACKAGE_kmod-usb-net-smsc95xx=y\n' \
             + '\' >> .config'

            // Add all required feeds to default config
            for (feed in customFeeds) {
                sh "grep -q 'src-.* ${feed[0]} .*' feeds.conf.default || \
                    echo 'src-git ${feed[0]} ${feed[2]}/${feed[1]}.git' >> feeds.conf.default"
            }

            // If specified override each feed with local clone
            sh 'cp feeds.conf.default feeds.conf'
            for (feed in customFeeds) {
                if (params."OVERRIDE_${feed[0].toUpperCase()}"?.trim()){
                    dir("feed-${feed[0]}") {
                        checkout([
                            $class: 'GitSCM',
                            branches: [[name: env."OVERRIDE_${feed[0].toUpperCase()}"]],
                            userRemoteConfigs: [[
                                refspec: '+refs/pull/*/head:refs/remotes/origin/PR-* \
                                    +refs/heads/*:refs/remotes/origin/*',
                                url: "${feed[2]}/${feed[1]}.git"
                            ]]
                        ])
                    }
                    sh "sed -i 's|^src-git ${feed[0]} .*|src-link ${feed[0]} ../feed-${feed[1]}|g' feeds.conf"
                }
            }
            sh 'cat feeds.conf.default feeds.conf .config'
            sh 'scripts/feeds update -a && scripts/feeds install -a'
            sh 'rm feeds.conf'
            sh 'make defconfig'
        }
        stage('Build') {
            // Add opkg signing key
            withCredentials([
                [$class: 'FileBinding', credentialsId: 'opkg-build-private-key', variable: 'PRIVATE_KEY'],
                [$class: 'FileBinding', credentialsId: 'opkg-build-public-key', variable: 'PUBLIC_KEY'],
            ]){
                // Attempt to build quickly and reliably
                try {
                    sh "cp ${env.PRIVATE_KEY} ${WORKSPACE}/key-build"
                    sh "cp ${env.PUBLIC_KEY} ${WORKSPACE}/key-build.pub"
                    sh "make -j4 V=s ${params.ALL_PACKAGES ? 'IGNORE_ERRORS=m' : ''}"
                } catch (hudson.AbortException err) {
                    // TODO BUG JENKINS-28822
                    if(err.getMessage().contains('script returned exit code 143')) {
                        throw err
                    }
                    echo 'Parallel build failed, attempting to continue in  single threaded mode'
                    sh "make -j1 V=s ${params.ALL_PACKAGES ? 'IGNORE_ERRORS=m' : ''}"
                } finally {
                    sh "rm ${WORKSPACE}/key-build*"
                }
            }
        }

        stage('Upload') {
            archiveArtifacts 'bin/*/*'
            if (params.ALL_PACKAGES) {
                archiveArtifacts 'bin/*/packages/**'
            }
            deleteDir()  // clean up the workspace to save space
        }
    }
}
node('boardfarm') {
    stage('Integration test') {
        deleteDir()

        unarchive mapping: ['bin/pistachio/*.ubi': '.']
        sh "cp bin/pistachio/*.ubi ${env.WEBSERVER_PATH}/image.ubi"

        sh "sshpass -p 'root' scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        ${env.OTA_DIRECTORY}/ota_update.sh ${env.OTA_DIRECTORY}/ota_verify.sh root@${env.WAN_IP}:~/"
        sh "sshpass -p 'root' ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        root@${env.WAN_IP} '/root/ota_update.sh http://${env.WEBSERVER_IP}/image.ubi 192.168.0.2'"
        sh 'sleep 180'

        sh 'echo "ifconfig eth0 up" > /dev/ttyUSB0'
        sh 'echo "ifconfig eth1 up" > /dev/ttyUSB0'
        sh 'sleep 10'
        sh 'echo "ifconfig eth0 192.168.1.1" > /dev/ttyUSB0'
        sh 'echo "ifconfig eth1 192.168.0.2" > /dev/ttyUSB0'

        sh 'echo "iptables -A forwarding_rule -i eth0 -j ACCEPT" > /dev/ttyUSB0'
        sh 'echo "iptables -A forwarding_rule -i eth1 -j ACCEPT" > /dev/ttyUSB0'
        sh 'echo "iptables -A forwarding_rule -o eth0 -j ACCEPT" > /dev/ttyUSB0'
        sh 'echo "iptables -A forwarding_rule -o eth1 -j ACCEPT" > /dev/ttyUSB0'

        sh 'echo "route add default gw 192.168.0.1" > /dev/ttyUSB0'
        sh 'sleep 10'
        sh 'echo "sed -i \'$ a nameserver 8.8.4.4\' /etc/resolv.conf" > /dev/ttyUSB0'
        sh 'sleep 10'

        sh "sshpass -p 'root' ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        root@${env.WAN_IP} \"/root/ota_verify.sh 192.168.0.2 && rm /root/ota_*\""

        sh "mkdir -p '${WORKSPACE}/results'"
        checkout([$class: "GitSCM",
            branches: [[ name: params.OVERRIDE_BOARDFARM?.trim() ?: "master" ]],
            extensions: [[ $class: "RelativeTargetDirectory",
            relativeTargetDir: "${WORKSPACE}/boardfarm" ]],
            userRemoteConfigs:
            [[ refspec: '+refs/pull/*/head:refs/remotes/origin/PR-* \
                +refs/heads/*:refs/remotes/origin/*',
            url: "https://github.com/CreatorDev/boardfarm.git"]] ])

        sh "export USER='jenkins'; \
        ${WORKSPACE}/boardfarm/bft -x ci40_passed_tests -n ci40_dut \
        -o ${WORKSPACE}/results -c ${WORKSPACE}/boardfarm/boardfarm_config.json -y"

        junit 'results/test_results.xml'
    }
}
