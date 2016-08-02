import sys
import cm_api
import time
import yaml
import requests
from requests.auth import HTTPBasicAuth
import ssl
from cm_api.api_client import ApiResource
import getpass

def get_services(cluster, type):
  return [ s for s in cluster.get_all_services() if s.type == type ]

def get_role_cfg_groups(svc, type):
  return [ r for r in svc.get_all_role_config_groups() if r.roleType == type ] 

def wait_for_commands():
  seen_running = False
  cnt = 0
  while True:
    cnt = cnt + 1
    time.sleep(1)
    if len(cm.get_commands()) > 0:
      seen_running = True
    if seen_running and len(cm.get_commands()) == 0 or (not seen_running and cnt >= 5):
      break

def api_get(path):
  req = requests.get('%s%s' % (cm_url, path), verify=False, auth=auth)
  return req.text

if len(sys.argv) != 9:
  print 'Syntax: %s <cm_host> <cm_port> <cm_user> <kerberos_ad_server> <kerberos_ad_realm> <kerberos_ad_ou> <kerberos_cm_principal> <ad_account_prefix>' % (sys.argv[0])
  exit(1)

cm_host = sys.argv[1]
cm_port = sys.argv[2]
cm_user = sys.argv[3]
kerberos_ad_server = sys.argv[4]
kerberos_ad_realm = sys.argv[5]
kerberos_ad_ou = sys.argv[6]
kerberos_cm_principal = sys.argv[7]
ad_account_prefix = sys.argv[8]

print "%s's password" % (cm_user,)
cm_pwd = getpass.getpass()
print "%s's password" % (kerberos_cm_principal,)
krb_pwd = getpass.getpass()

auth = HTTPBasicAuth(cm_user, cm_pwd)

cm_url = 'https://%s:%s' % (cm_host, cm_port)
try:
  req = api_get('/')
  use_tls = True
except:
  cm_url = 'http://%s:%s' % (cm_host, cm_port)
  req = api_get('/')
  use_tls = False

ret = api_get('/api/version')
api_version = int(ret.replace('v', ''))

api = ApiResource(cm_host, cm_port, cm_user, cm_pwd, use_tls=use_tls, version=api_version)
cm = api.get_cloudera_manager()

print 'Configure Kerberos parameters'
cm.update_config({
  'AD_ACCOUNT_PREFIX':    ad_account_prefix,
  'AD_KDC_DOMAIN':        kerberos_ad_ou,
  'KDC_HOST':             kerberos_ad_server,
  'KDC_TYPE':             'Active Directory',
  'KRB_MANAGE_KRB5_CONF': 'true',
  'KRB_ENC_TYPES':        'aes256-cts',
  'SECURITY_REALM':       kerberos_ad_realm
})

print 'Import KDC credentials'
cmd = cm.import_admin_credentials(kerberos_cm_principal, krb_pwd).wait()
if not cmd.success:
  raise Exception('Command %s failed (%s)' % (cmd.name, cmd.resultMessage))

print 'Configure Kerberos for cluster services'
if api_version >= 11:
  for cluster in api.get_all_clusters():
    cmd = cluster.configure_for_kerberos(1004, 1006).wait()
    if not cmd.success:
      raise Exception('Command %s failed (%s)' % (cmd.name, cmd.resultMessage))
else:
  CFG = yaml.load('''
  ZOOKEEPER:
    config:
      enableSecurity: true
  HDFS:
    config:
      hadoop_security_authentication: kerberos
      hadoop_security_authorization: true
    roleConfigGroups:
      DATANODE:
        dfs_datanode_data_dir_perm: 700
        dfs_datanode_http_port: 1006
        dfs_datanode_port: 1004
  HBASE:
    config:
      hbase_security_authentication: kerberos
      hbase_security_authorization: true
  SOLR:
    config:
      solr_security_authentication: kerberos
  ''')

  for cluster in api.get_all_clusters():
    for svc_type in ['ZOOKEEPER', 'HDFS', 'HBASE', 'SOLR']:
      print '  Service %s' % (svc_type,)
      for svc in get_services(cluster, svc_type):
        if 'config' in CFG[svc_type]:
          svc.update_config(CFG[svc_type]['config'])
        if 'roleConfigGroups' in CFG[svc_type]:
          for roleType in CFG[svc_type]['roleConfigGroups']:
            for rcg in get_role_cfg_groups(svc, roleType):
              rcg.update_config(CFG[svc_type]['roleConfigGroups'][roleType])
      wait_for_commands()

  for cluster in api.get_all_clusters():
    for hue in get_services(cluster, 'HUE'):
      if len(hue.get_roles_by_type('KT_RENEWER')) == 0:
        hostId = hue.get_roles_by_type('HUE_SERVER')[0].hostRef.hostId
        hue.create_role('KT_RENEWER-1', 'KT_RENEWER', hostId)

print 'Wait for Generate Missing Credentials command to finish'
wait_for_commands()

print 'Stop all services'
for cluster in api.get_all_clusters():
  cluster.stop().wait()
cm.get_service().stop().wait()

print 'Deploy client configs'
for cluster in api.get_all_clusters():
  cluster.deploy_cluster_client_config().wait()
  cluster.deploy_client_config().wait()

print 'Start all services'
for cluster in api.get_all_clusters():
  cluster.start().wait()
cm.get_service().start().wait()
