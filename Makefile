.PHONY: all service-discovery rollback

file  := ./prometheus/prometheus.yml
file2 := ./prometheus/targets.json
local := 127.0.0.1

RESOURCE_GROUP ?= prometheus-stack-dev-rg
VM_NAME        ?= prometheus-stack-vm

pub_ip := $(shell az vm list-ip-addresses \
              --resource-group $(RESOURCE_GROUP) \
              --name $(VM_NAME) \
              --query "[0].virtualMachine.network.publicIpAddresses[0].ipAddress" \
              --output tsv 2>/dev/null || curl -s ifconfig.io)

service-discovery:
	@echo "***************************************"
	@echo "****SERVICE DISCOVERY OF PUBLIC IP*****"
	@echo "*****PUBLIC IPADDRESS : $(pub_ip)******"
	@echo "******LOOPBACK ADDRESS : $(local)******"
	@sed -i "s/$(local)/$(pub_ip)/g" $(file)
	@echo "******UPDATED FILE prometheus.yml******"
	@cat "$(file)"
	@sed -i "s/$(local)/$(pub_ip)/g" $(file2)
	@echo "*******UPDATED FILE targets.json*******"
	@cat "$(file2)"
	@echo "***************************************"

rollback:
	@echo "***************************************"
	@echo "*****ROLLBACK OF SERVICE DISCOVERY*****"
	@echo "******PUBLIC IPADDRESS : $(pub_ip)*****"
	@echo "******LOOPBACK ADDRESS : $(local)******"
	@sed -i "s/$(pub_ip)/$(local)/g" $(file)
	@echo "******UPDATED FILE prometheus.yml******"
	@cat "$(file)"
	@sed -i "s/$(pub_ip)/$(local)/g" $(file2)
	@echo "*******UPDATED FILE targets.json*******"
	@cat "$(file2)"
	@echo "****************************************"

all: service-discovery