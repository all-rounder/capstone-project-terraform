#cloud-config
package_update: true
package_upgrade: true

packages:
  - git
  - python3-pip
  - curl
  - unzip
  - apt-transport-https
  - ca-certificates
  - gnupg
  - lsb-release
  - software-properties-common

# Use cloud-init’s Ansible module to do an ansible-pull
ansible:
  install_method: pip
  package_name: ansible-core
  pull:
    - url: "{{ ansible_git_repo }}"
      playbook_names: ["{{ ansible_playbook }}"]
