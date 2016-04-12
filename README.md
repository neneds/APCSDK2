# APCSDK2

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

APC SDK Para desenvolvedores iOS

Este SDK atualmente na versão 1.0 foi desenvolvido para encapsular a lógica de acesso aos endpoints dos Aplicativos Cívicos.
Totalmente desenvolvido em swift, possui a realease 1.0 estável funcionando para qualquer projeto Swift e Objective C. 

# Dependências
Alamofire ~> 3.3.0. 

# Features
Métodos provendo: Cadastro, Login primário do TCU, Login com o Facebook,Login com o Twitter, redefinir minha senha e 
validação de Token.

# Instalação

1 - Instale o Home Brew via terminal

    usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

2 - Instale o Carthage na sua máquina via terminal

    brew install carthage

3 - Abra o diretório do seu projeto no terminal
  
    cd user/myproject

4 - Crie o Cartfile no seu projeto

    touch Cartfile

5 - Abra o Cartfile com o Xcode

    open -a Xcode Cartfile

5 - Adicione estas duas linhas  no Cartfile criado

    github "Alamofire/Alamofire" ~> 3.3
    github "neneds/APCSDK2" ~> 1.0.3

6 - Dê um carthage update

    carthage update --platform iOS

Pronto, você já baixou a framework para a pasta do seu projeto elas estão em:  usr/myproject/Carthage/Build/iOS. Agora você vai adicionar as frameworks no seu projeto.

7 - Vá no Target, clique em 'Build Phases' e adicione o 'New Run Script Phases'
<img src="https://ap.imagensbrasil.org/images/CapturadeTela2016-04-12as16.23.46.png" alt="CapturadeTela2016-04-12as16.23.46.png" border="1" width="500">

8 - Após adicionar o Run Script você deve colocar o seguinte link no script

    /usr/local/bin/carthage copy-frameworks

9 - Adione este link no 'Input Files'

    $(SRCROOT)/Carthage/Build/iOS/Alamofire.framework

O seu Run Script vai ficar da seguinte forma

<img src="https://ap.imagensbrasil.org/images/CapturadeTela2016-04-12as16.41.47.png" alt="CapturadeTela2016-04-12as16.41.47.png" border="1" width="500">

10 - Adicione o Framework APCAccessSDK no Embedded Binaries do seu projeto

    $(SRCROOT)/Carthage/Build/iOS/APCAccessSDK

11 - 

