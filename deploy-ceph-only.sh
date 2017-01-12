source ~/stackrc
time openstack overcloud deploy --templates \
--compute-scale 0 --ceph-storage-scale 1 \
-e ~/tht/ceph-only.yaml
