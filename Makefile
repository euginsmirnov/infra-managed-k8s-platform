ANSIBLE_DIR=automation/ansible

.PHONY: deps bootstrap kubeadm-init kubeadm-join ping

deps:
	cd $(ANSIBLE_DIR) && ansible-galaxy collection install -r requirements.yml

ping:
	cd $(ANSIBLE_DIR) && ansible all -m ping

bootstrap:
	cd $(ANSIBLE_DIR) && ansible-playbook playbooks/bootstrap.yml

kubeadm-init:
	cd $(ANSIBLE_DIR) && ansible-playbook playbooks/kubeadm_init.yml

kubeadm-join:
	cd $(ANSIBLE_DIR) && ansible-playbook playbooks/kubeadm_join.yml
