#Download base image ubuntu 20.04
FROM ubuntu:groovy

# Disable Prompt During Packages Installation
ARG DEBIAN_FRONTEND=noninteractive

# Runtime environemnts
# Replace values with username, password and FQDN of GP Portal
ENV GP_USERNAME="CHANGE_ME"
ENV GP_PASSWORD="CHANGE_ME"
ENV GP_HOST="CHANGE_ME"
#ENV GP_MACHINECERT=docker_machine_cert.crt
#ENV GP_MACHINECERTKEY=docker_machine_cert.key
ENV MINIMAL="false"
#ENV NMAP_TARGET="127.0.0.1"
ENV BITTORRENT="true"
ENV WGET_FTP="true"
ENV WGET_SMTP="true"
ENV WGET_SYSLOG="true"
ENV SMTP="true"
ENV SMTP_SERVER="mail.smtpbucket.com:8025"
ENV NMAP="true"
ENV HIPREPORT="true"
ENV CURL_PANDB_URL="true"
ENV EICAR_FILES="true"
ENV TIMEOUT="3600"
ENV IFTOP="false"
ENV GET_GP_CERTS="true"

WORKDIR /opt/gp-flux

RUN mkdir logs
RUN mkdir certificates-gp
RUN mkdir downloads
RUN mkdir downloads/bittorrent-transmission
RUN mkdir downloads/bittorrent-transmission-incomplete

RUN apt update && apt install -y \
  sudo \
  net-tools\
  curl\
  traceroute\
  inetutils-ping\
  dnsutils\
  ethtool\
  python3\
  python3-pip\
  openconnect\
  transmission-cli\
  transmission-daemon\
  wget\
  nano\
  ca-certificates\
  nmap\
  iftop\
  swaks\
&& apt clean

COPY start.sh .
COPY /scripts ./scripts/
COPY /certificates/ .
COPY /transmission-daemon/watch downloads/bittorrent-transmission-watch
COPY /transmission-daemon/settings.json transmission-daemon/settings.json
RUN chmod +x start.sh
RUN chmod -R +x scripts/

# Install Python prerequisites
RUN pip3 install -r scripts/noisy/requirements.txt

#ENTRYPOINT ["bash"]
CMD ["bash", "./start.sh"]