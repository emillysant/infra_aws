ami-830c94e3
ami-0a70b9d193ae8a799

## ?Requisitos do projeto
1 - Terraform
2 - AWS CLI

## Iniciando projeto

### Crie uma chave ssh (ex: demo)

1 - Acessar a aws > ec2
2 - Acessar "par de chaves"
3 - Criar uma chave ssh, nome: demo, tipo: rds, formato: .pem, tags: nome - demo
4 - Clique em criar e baixe o arquivo demo.pem

### Rode os comandos 
```terraform init```
``` terraform apply```

### Acesse o ec2 por ssh
1 - Acessar a aws > ec2
2 - Espere a instancia ec2-user ficar disponivel clique em conectar > ssh
3 - Como sugerido rode o comando ... exemplo:
``` chmod 400 "demo.pem" ```
``` ssh -i "demo.pem" ec2-user@ec2-35-86-56-139.us-west-2.compute.amazonaws.com ```

### Copiar o arquivo para a VM aws
1 - Abra outro terminal e rode na sua maquina local
``` scp -i "demo.pem" /home/emilly/projetos/IngestaoAPI/main.py ec2-user@ec2-35-86-56-139.us-west-2.compute.amazonaws.com:~/ ```
``` scp -i "demo.pem" /home/emilly/projetos/IngestaoAPI/requirements.txt ec2-user@ec2-35-86-56-139.us-west-2.compute.amazonaws.com:~/ ``` 

### Executando ingestao por API
1 - Cria uma venv
```python3 -m venv venv```
2 - ativando a venv
```chmod +x venv/bin/activate ```
3 - dentro do terminal, conectado a maquina virtual, instale as dependencias: 
```pip install -r requirements.txt```
4 - Rode a ingestao
``` python main.py```# infra_aws
