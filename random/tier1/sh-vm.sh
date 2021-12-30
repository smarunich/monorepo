# # create dedicated user account “istio-proxy” for VM onboarding
# sudo useradd --create-home istio-proxy

# # sudo into the dedicated user
# sudo su - istio-proxy

# # configure SSH access for the new user account
# mkdir -p $HOME/.ssh
# chmod 700 $HOME/.ssh
# touch $HOME/.ssh/authorized_keys
# chmod 600 $HOME/.ssh/authorized_keys

# #
# # Add your SSH public key to $HOME/.ssh/authorized_keys
# #

# # go back to the privileged user
# exit

sudo apt update
sudo apt install -y docker.io

sudo usermod -aG docker istio-proxy

sudo mkdir -p /etc/istio-proxy
sudo chmod  775 /etc/istio-proxy
sudo chown istio-proxy:istio-proxy /etc/istio-proxy