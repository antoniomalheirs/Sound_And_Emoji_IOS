# iOS Sound & Emoji Module for Android

[![Magisk](https://img.shields.io/badge/Magisk-Compatible-red.svg)](https://github.com/topjohnwu/Magisk)
[![KernelSU](https://img.shields.io/badge/KernelSU-Compatible-blue.svg)](https://github.com/tiann/KernelSU)
[![iOS Style](https://img.shields.io/badge/Style-iOS_18.4-lightgrey.svg)](https://www.apple.com/ios/)

Este módulo substitui os sons e emojis da interface do seu Android pelos do iOS, sem alterar o sistema. Ele foi projetado para ser totalmente compatível com **Magisk** e **KernelSU** (incluindo o KernelSU Next), proporcionando uma transformação limpa e perfeita.

---

## ⚙️ Como Instalar

1.  **Baixe** a versão mais recente do módulo na [página de Releases](https://github.com/antoniomalheirs/Sound_And_Emoji_IOS/releases).
2.  Abra o aplicativo **Magisk** ou **KernelSU**.
3.  Vá para a seção **Módulos**.
4.  Toque em **"Instalar a partir do armazenamento"** e selecione o arquivo `.zip` que você baixou.
5.  Após a instalação ser concluída, toque em **"Reiniciar"** para aplicar as alterações.

## ✨ Funcionalidades

* **Sons da UI do iOS:** Substitui os sons de interação padrão do Android (bloqueio/desbloqueio, carregamento, cliques do teclado) por seus equivalentes do iOS.
* **Emojis Mais Recentes do iOS:** Atualiza a fonte do seu sistema para incluir os emojis mais recentes do iOS 18.
* **Instalação Systemless:** Modifica seu sistema sem alterar a partição `/system`, garantindo a integridade do seu dispositivo e facilitando a desinstalação.
* **Ampla Compatibilidade:** Funciona com os ambientes Magisk e KernelSU.

---

## 📝 Changelog

Um histórico detalhado de atualizações e melhorias no módulo.

* **v1.1.0 (Mais recente)**
    * Atualizados todos os arquivos do módulo para alinhar com o **iOS 18.4**.
* **v1.0.9**
    * Melhorado o script `customize.sh` para uma instalação mais confiável no Magisk.
* **v1.0.8**
    * Adicionado feedback de vibração na tela de bloqueio para corresponder ao novo som de desbloqueio.
* **v1.0.7**
    * Criado um script de desinstalação rápida para fácil remoção.
* **v1.0.6**
    * Desenvolvida uma interface de usuário para a página web do repositório do módulo.
* **v1.0.5**
    * Atualizado o conjunto de emojis para o **Emoji 18.1**.
* **v1.0.4**
    * Otimizado ainda mais o módulo removendo arquivos de recursos redundantes.
* **v1.0.3**
    * Limpos e removidos arquivos desnecessários para reduzir o tamanho do módulo.
* **v1.0.2**
    * Implementado um sistema de atualização de pacotes para versões futuras.
* **v1.0.1**
    * Lançamento inicial.

---

## 🙏 Créditos e Agradecimentos

Este projeto foi possível graças ao trabalho fundamental e à inspiração de outros na comunidade de modificação do Android.

* [**topjohnwu**](https://github.com/topjohnwu) - Por criar o **Magisk**, a ferramenta revolucionária para modificação systemless.
* [**tiann**](https://github.com/tiann) - Por desenvolver o **KernelSU**, fornecendo uma alternativa poderosa baseada no kernel.
* [**TheGabrielHoward**](https://github.com/TheGabrielHoward/IOS-sounds) - Por fornecer alguns dos arquivos de som do iOS e a ideia inicial para um módulo de substituição de som.
* [**dtingley11**](https://github.com/dtingley11/KernelSU-iOS-Emoji) - Pelo código de substituição de fonte que lida de forma inteligente com diferentes configurações de dispositivos Android.
