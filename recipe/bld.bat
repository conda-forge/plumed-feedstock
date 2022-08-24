cygpath -u %PREFIX% > prefix.txt
set /p UNIX_PREFIX=<prefix.txt

bash configure --prefix=%UNIX_PREFIX% --disable-openmp
make -j %CPU_COUNT%
make install
