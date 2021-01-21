// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import hudson.model.AbstractModelObject
import hudson.model.Node
import hudson.model.Slave
import hudson.slaves.DumbSlave


import hudson.slaves.ComputerLauncher
import hudson.slaves.JNLPLauncher


import hudson.slaves.ComputerLauncher

import groovy.json.JsonBuilder

import jenkins.model.Jenkins


pipeline {
    agent none
    
    environment {
        JENKINS_CRED = credentials('Jenkins-SIM')
        CML_CRED = credentials('CML-SIM-CRED')
//         CML_URL = env.CML-URL
    }
    stages {
        stage('Prepare Jenkins...') {
            agent { 
                node { 
                    label 'master'
                } 
            }
            steps {
                echo 'Collecting variables'
                echo '--------------------'
                echo "${CML_URL}"
                script { 
                    gitCommit = sh(returnStdout: true, script: 'git rev-parse --short  HEAD').trim()
//                     jc = sh(returnStdout: true, script: 'curl --insecure -u ' + "${JENKINS_CRED_USR}:${JENKINS_CRED_PSW}" + ' \'' + "${env.JENKINS_URL}" + 'crumbIssuer/api/xml?xpath=concat(//crumbRequestField,":",//crumb)\'').trim()
//                     sh(returnStdout: true, script: 'echo HHHHHHHH; echo $jc')
//                     JenkinsCrumb = jc.substring(14)
                }
            }
        }
        stage('Deploying Stage 0 simulation (Box) in CML') {
            agent { 
                node { 
                    label 'master'
                } 
            }
            steps {
                echo "Prepare stage 0 simulation environment"
                echo "--------------------------------------"

                checkout scm

                startsim(0)
            
            }
        }
        stage('Stage 0: Deploying and testing Box in CML') {
            steps {
                node ("stage0-" + gitCommit as String) {
                    echo "Switching to jenkins agent: stage0-" + "${gitCommit}"

                    checkout scm

                    echo "Set stage 0 box variables"
                    echo "--------------------------------------"
                    sh "cd roles/box/vars/ && ln -s stage0.yml main.yml"

                    echo "Start stage 0 playbook"
                    ansiblePlaybook installation: 'ansible', inventory: 'vars/stage0', playbook: 'stage0.yml', extraVars: ["stage": "0"], extras: '-vvvv'
                }
                node ('master') {
                    echo "Switching to jenkins agent: master"

                    echo 'Stopping CML simulation'
                    sh 'curl --insecure -X GET -u ' + "${CML_CRED}" + ' ' + "${CML_URL}"  + '/simengine/rest/stop/stage0-' + "${gitCommit}"
                }
            }
        }
        stage('Deploying Stage 1 simulation (Topology) in CML') {
            agent { 
                node { 
                    label 'master'
                } 
            }
            steps {
                echo "Prepare stage 1 simulation environment"
                echo "--------------------------------------"

                checkout scm

                startsim(1)
            
            }
        }
        stage('Stage 1: Configuring interfaces and links in CML') {
            steps {
                node ("stage1-" + gitCommit as String) {
                    echo "Switching to jenkins agent: stage1-" + "${gitCommit}"

                    checkout scm

                    echo "Set stage 1 topology variables"
                    echo "--------------------------------------"
                    sh "cd roles/box/vars/ && ln -s stage1.yml main.yml"
                    sh "cd roles/topology/vars/ && ln -s stage1.yml main.yml"

                    echo "Start stage 0 playbook"
                    ansiblePlaybook installation: 'ansible', inventory: 'vars/stage1', playbook: 'stage0.yml', extraVars: ["stage": "1"]

                    echo "Start stage 1 playbook"
                    ansiblePlaybook installation: 'ansible', inventory: 'vars/stage1', playbook: 'stage1.yml', extraVars: ["stage": "1"], extras: '-vvvv'
                }
                node ('master') {
                    echo "Switching to jenkins agent: master"

                    echo 'Stopping CML simulation'
                    sh 'curl --insecure -X GET -u ' + "${CML_CRED}" + ' ' + "${CML_URL}"  + '/simengine/rest/stop/stage1-' + "${gitCommit}"

                    echo 'Removing Jenkins Agent'
                    deleteSim(stage)
//                     sh 'curl --insecure -L -s -o /dev/null -u ' + "${JENKINS_CRED_USR}:${JENKINS_CRED_PSW}" + ' -H "Content-Type:application/x-www-form-urlencoded" -H "' + "${jc}" + '" -X POST "' + "${env.JENKINS_URL}" + 'computer/stage1' + "-" + "${gitCommit}" + '/doDelete"'
                }
            }
        }
     }
    post {
        success {
            echo 'I succeeded!'
            //mail to: 'architects@example.com',
            //    subject: "Success for Pipeline: ${gitCommit}",
            //    body: "Success for ${env.BUILD_URL}"
        }
        failure {
            echo 'You are not a Jedi yet....I failed :('
            //    mail to: 'architects@example.com',
            //    subject: "Failed Pipeline: ${gitCommit}",
            //    body: "Something is wrong with ${env.BUILD_URL}"
        }
        changed {
            echo 'Things were different before...'
        }
        cleanup {
            echo 'Cleaning up....'
            echo 'Removing Jenkins Agent'
            deleteSim("remote", stage)
        }
    }
}

def startsim(stage) {


// //     ComputerLauncher launcher = new ComputerLauncher();
//     ComputerLauncher launcher = new JNLPLauncher(true)
//
//     DumbSlave worker = new DumbSlave("stage${stage}-${gitCommit}", "/root", launcher)
//
//     worker.nodeDescription = "NetCICD+host+for+commit+is+stage${stage}-${gitCommit}"
//     worker.numExecutors = "1"
// //     worker.remoteFS = "/root"
//     worker.labelString = "worker-${stage}-${gitCommit}"
//     worker.mode = "EXCLUSIVE"
// //     worker.retentionStrategy = retentionStrategy()

    echo 'Creating Jenkins build node for commit: ' + "${gitCommit}"
    jenkinsWorker("add", stage)

    echo 'Retrieving Agent Secret'
    script {
        agentSecret = jenkins.model.Jenkins.getInstance().getComputer("stage" + "${stage}" + "-" + "$gitCommit").getJnlpMac()
    }
    echo "secret = " + "${agentSecret}"

    timeout(time: 30, unit: "MINUTES") {
        script {
            waitUntil {
                sleep 60
                cml_state_json = sh(returnStdout: true, script: 'curl --insecure -X GET -u ' + "${CML_CRED}" + ' ' + "${CML_URL}" + '/simengine/rest/nodes/stage' + "${stage}" + '-' + "${gitCommit}").trim()
                def c_state = readJSON text: "${cml_state_json}"
                cml_state = c_state["stage" + "${stage}" + "-"+"${gitCommit}"]
                //echo "${cml_state}"
                cs = cml_state.collect {it.value.reachable}
                echo "Node reachability: " + "${cs}"
                test =  cs.every {element -> element == true}
                echo "Simulation ready? " + "${test}"
                if (test) {
                    return true
                } else {
                    return false
                }
            }
        }
    }
    return null
}

def deleteSim(stage) {
    echo 'Deleting Jenkins build node for commit: ' + "${gitCommit}"
    jenkinsWorker("remove", stage)
}

@NonCPS
def jenkinsWorker(action, stage) {
    DumbSlave worker = new DumbSlave("stage${stage}-${gitCommit}", "/root", new JNLPLauncher(true))

    worker.nodeDescription = "NetCICD+host+for+commit+is+stage${stage}-${gitCommit}"
    worker.numExecutors = "1"
    worker.labelString = "worker-${stage}-${gitCommit}"
    worker.mode = "EXCLUSIVE"

    if (action == "add") {
        Jenkins.instance.addNode(worker)
    } else {
        Jenkins.instance.removeNode(worker)
    }
}
