
First activate the neuroviz env
source neuroviz/bin/activate

Then run streamlit on a different port
streamlit run app_V3.py --server.port 5811

To serve it outside using uboot use reverse port fw

[on uboot]
make sure that  the line
GatewayPorts yes
in /etc/ssh/sshd_config
is set to yes

sudo service ssh restart

[on stroom]
ssh -R 5811:localhost:5811 leonardo@159.223.212.145
