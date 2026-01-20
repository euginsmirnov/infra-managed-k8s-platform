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

versions:
	cd automation/ansible && ansible control_plane:workers -m shell -a 'kubeadm version && kubelet --version && kubectl version --client=true && containerd --version'

ingress:
	cd automation/ansible && ansible-playbook playbooks/ingress_nginx.yml

ufw-ingress:
	cd automation/ansible && ansible-playbook playbooks/ufw_ingress_ports.yml

monitoring:
	cd automation/ansible && ansible-playbook playbooks/monitoring.yml

logging:
	cd automation/ansible && ansible-playbook playbooks/logging.yml

storage:
	cd automation/ansible && ansible-playbook playbooks/storage.yml

cert-manager:
	ansible-playbook -i automation/ansible/inventory automation/ansible/playbooks/cert-manager.yml

vault:
	ansible-playbook -i automation/ansible/inventory automation/ansible/playbooks/vault.yml