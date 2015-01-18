which lsb_release && lsb_release -ds

install_linux() {
  sudo apt-get update -yqq
  sudo apt-get install -y ${LISP:-sbcl}
  test -z "$M32" || sudo apt-get install -y gcc-multilib
}

install_yum() {
  sudo yum install -y ${LISP:-sbcl}
}

download_sbcl() {
  sbcl=sbcl-1.2.4-x86-64-linux
  wget http://prdownloads.sourceforge.net/sbcl/$sbcl-binary.tar.bz2
  tar xjf $sbcl-binary.tar.bz2
  (export INSTALL_ROOT=$PWD/sbcl && cd $sbcl && sh install.sh)
}

install_osx() {
  brew update > /dev/null
  brew install ${LISP:-clozure-cl}
}

$1
