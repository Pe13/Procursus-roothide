#! /bin/sh

mkdir procursus_tmp
cd procursus_tmp

curl -LO https://cameronkatri.com/zstd
if [[ $(uname -m) == 'arm64' ]]; then
  curl -L https://apt.procurs.us/bootstraps/big_sur/bootstrap-darwin-arm64.tar.zst -o bootstrap.tar.zst
elif [[ $(uname -m) == 'x86_64' ]]; then
  curl -L https://apt.procurs.us/bootstraps/big_sur/bootstrap-darwin-amd64.tar.zst -o bootstrap.tar.zst
else
 echo "Error: Unrecognized system arch."
 exit 1
fi

chmod +x zstd
./zstd -d bootstrap.tar.zst
sudo tar -xpkf bootstrap.tar -C /
printf 'export PATH="/opt/procursus/bin:/opt/procursus/sbin:/opt/procursus/games:$PATH"\nexport CPATH="$CPATH:/opt/procursus/include"\nexport LIBRARY_PATH="$LIBRARY_PATH:/opt/procursus/lib"\n' | tee -a ~/.zprofile
export PATH="/opt/procursus/bin:/opt/procursus/sbin:/opt/procursus/games:$PATH"
export CPATH="$CPATH:/opt/procursus/include"
export LIBRARY_PATH="$LIBRARY_PATH:/opt/procursus/lib"
sudo apt update
sudo apt full-upgrade -y

cd ..
rm -r procursus_tmp