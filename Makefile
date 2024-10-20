# Replace this with your own github.com/<username>/<repository>
GO_MODULE := github.com/disco07/bank-proto

.PHONY: clean
clean:
ifeq ($(OS), Windows_NT)
	if exist "protogen" rd /s /q protogen
	mkdir protogen\go
else
	rm -fR ./protogen
	mkdir -p ./protogen/go
endif


.PHONY: protoc-go
protoc-go:
	cd proto && find . -name "*.proto" \
        ! -path "./google/*" \
        ! -path "./**/google/*" \
        ! -path "./protoc-gen-openapiv2/*" \
        -exec protoc -I . \
         			--go_out=../protogen/go \
                    --go_opt=paths=source_relative \
                    --go-grpc_out=../protogen/go \
                    --go-grpc_opt=paths=source_relative {} +

.PHONY: build
build: clean protoc-go


.PHONY: pipeline-init
pipeline-init:
	sudo apt-get install -y protobuf-compiler golang-goprotobuf-dev
	go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
	go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest


.PHONY: pipeline-build
pipeline-build: pipeline-init build

## gateway ##

.PHONY: clean-gateway
clean-gateway:
ifeq ($(OS), Windows_NT)
	if exist "protogen\gateway" rd /s /q protogen\gateway
	mkdir protogen\gateway\go
	mkdir openapi
else
	rm -fR ./protogen/gateway
	mkdir -p ./protogen/gateway/go
	mkdir -p ./openapi
endif


.PHONY: protoc-go-gateway
protoc-go-gateway:
	cd proto && find . -name "*.proto" \
            ! -path "./google/*" \
            ! -path "./**/google/*" \
            ! -path "./protoc-gen-openapiv2/*" \
            -exec protoc -I . \
            	--grpc-gateway_out ../protogen/gateway/go \
				--grpc-gateway_opt logtostderr=true \
				--grpc-gateway_opt paths=source_relative \
				--grpc-gateway_opt standalone=true \
				--grpc-gateway_opt generate_unbound_methods=true {} +

.PHONY: protoc-openapiv2-gateway
protoc-openapiv2-gateway:
	cd proto && find . -name "*.proto" \
                ! -path "./google/*" \
                ! -path "./**/google/*" \
            	! -path "./protoc-gen-openapiv2/*" \
				-exec protoc -I . \
					--openapiv2_out ../openapi \
					--openapiv2_opt logtostderr=true \
					--openapiv2_opt output_format=yaml \
					--openapiv2_opt generate_unbound_methods=true \
					--openapiv2_opt allow_merge=true {} +

.PHONY: build-gateway
build-gateway: clean-gateway protoc-go-gateway


.PHONY: pipeline-init-gateway
pipeline-init-gateway:
	go install github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-grpc-gateway@latest
	go install github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-openapiv2@latest


.PHONY: pipeline-build-gateway
pipeline-build-gateway: pipeline-init-gateway build-gateway protoc-openapiv2-gateway
