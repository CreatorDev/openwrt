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
        stringParam(defaultValue: '', description: 'Set version, if blank job number will be used.',
            name: 'VERSION'),
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
            echo 'Setting default config'
            sh 'echo \'' \
             + 'CONFIG_TARGET_pistachio=y\n' \
             + 'CONFIG_TARGET_pistachio_marduk=y\n' \
             + 'CONFIG_TARGET_pistachio_marduk_marduk=y\n' \
             + '\' >> .config'

            // Package server config
            if (params.VERSION) {
                echo 'Updating server location for package downloads'
                sh "sed -i '/^CONFIG_VERSION_REPO/s/latest/ci40-${params.VERSION}/' .config"
            }

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

            // Add all required feeds to default config
            for (feed in customFeeds) {
                sh "grep -q 'src-.* ${feed[0]} .*' feeds.conf.default || \
                    echo 'src-git ${feed[0]} ${feed[2]}/${feed[1]}.git' >> feeds.conf.default"
            }

            // If specified override each feed with local clone
            sh 'cp feeds.conf.default feeds.conf'
            for (feed in customFeeds) {
                if (params."OVERRIDE_${feed[0].toUpperCase()}"?.trim()){
                    dir("feed-${feed[1]}") {
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
