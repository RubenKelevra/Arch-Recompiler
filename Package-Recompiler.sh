

# Recompile Packages Automatically

#Paths and Filename-Definitions
db_folder='/var/db/arch-recompiler'
deps_db='deps.db'
expl_db='explicit.db'
igno_db='ignore.list'

#Definitions
default_igno_list='linux
linux-lts
linux-headers
linux-lts-headers'

#In-Memory Databases
declare -A deps_indb
declare -A expl_indb
igno_indb=()

#Flags
create_deps_db=0
create_expl_db=0
create_igno_db=0
fix_filerights=0

echo 'Init completed.'

if [ ! -d "$db_folder" ]; then
  echo 'db-folder does not exist, creating new database-folder...'
  mkdir -p "$db_folder" >/dev/null 2>&1
  if test $? -ne 0; then
    echo "can't create dir, trying with sudo"
    sudo mkdir -p "$db_folder" >/dev/null 2>&1
    if test $? -ne 0; then
      echo "mkdir failed.";exit 1
    fi
    echo "changing rights for the folder with sudo..."
    sudo chown $(whoami): "$db_folder"
    if test $? -ne 0; then
      echo "chown failed.";exit 1
    fi
    sudo chmod 600 "$db_folder"
    if test $? -ne 0; then
      echo "chmod failed.";exit 1
    fi
  fi
fi

echo 'Checking Database...'
if [ ! -f "$db_folder/$deps_db" ]; then
  echo 'depency-packages database-file does not exist, going to create a new one...'
  create_deps_db=1
fi
if [ ! -f "$db_folder/$expl_db" ]; then
  echo 'explicit-packages database-file does not exist, going to create a new one...'
  create_expl_db=1
fi
if [ ! -f "$db_folder/$igno_db" ]; then
  echo 'ignore-package list-file does not exist, going to create a new one with default-list...'
  create_igno_db=1
fi

echo 'Checking file-rights...'
touch "$db_folder/$deps_db" >/dev/null 2>&1
if test $? -ne 0; then
  fix_filerights=1
fi
touch "$db_folder/$expl_db" >/dev/null 2>&1
if test $? -ne 0; then
  fix_filerights=1
fi
touch "$db_folder/$igno_db" >/dev/null 2>&1
if test $? -ne 0; then
  fix_filerights=1
fi

if [ $fix_filerights ]; then
  echo "insufficient file-rights, try to fix this with sudo..."
  sudo chown $(whoami): -R "$db_folder"
  if test $? -ne 0; then
    echo "chown failed.";exit 1
  fi
  sudo chmod 600 -R "$db_folder"
  if test $? -ne 0; then
    echo "chmod failed.";exit 1
  fi 
fi
unset fix_filerights

if [ $create_deps_db -o $create_expl_db -o $create_igno_db ]; then
  echo "Creating databases ..."
  if [ $create_deps_db ]; then
    echo "  Depency-packages database..."
    echo "" > "$db_folder/$deps_db" 2>&1 #pacman -Qdn
    if test $? -ne 0; then
      echo "failed.";exit 1
    fi
  fi
  if [ $create_expl_db ]; then
    echo "  Explicit-packages database..."
    echo "" > "$db_folder/$expl_db" 2>&1 #pacman -Qen
    if test $? -ne 0; then
      echo "failed.";exit 1
    fi
  fi
  if [ $create_igno_db ]; then
    echo "  Ignore-packages list..."
    echo "$default_igno_list" > "$db_folder/$igno_db" 2>&1
    if test $? -ne 0; then
      echo "failed.";exit 1
    fi
  fi
fi

echo "Locking databases..."
[ -f "$db_folder/$deps_db.lock" ] && (echo "ERROR: Depency-packages database locked.";exit 1)
touch "$db_folder/$deps_db.lock" >/dev/null 2>&1
if test $? -ne 0; then
  echo "ERROR: Can't lock depency-packages database.";exit 1
fi
[ -f "$db_folder/$expl_db.lock" ] && (echo "ERROR: Explicit-packages database locked.";exit 1)
touch "$db_folder/$expl_db.lock" >/dev/null 2>&1
if test $? -ne 0; then
  echo "ERROR: Can't lock explicit-packages database.";exit 1
fi
[ -f "$db_folder/$igno_db.lock" ] && (echo "ERROR: Ignore-packages database locked.";exit 1)
touch "$db_folder/$igno_db.lock" >/dev/null 2>&1
if test $? -ne 0; then
  echo "ERROR: Can't lock ignore-packages database.";exit 1
fi

echo "Loading databases..."

tmp1=""
tmp2=""
echo "  Depency-packages database..."
while read e; do
  tmp1=$(echo $e | cut -d' ' -f1)
  tmp2=$(echo $e | cut -d' ' -f2)
  if [ ! -z "$tmp1" -a ! -z "$tmp2" ]; then
    deps_indb["$tmp1"]="$tmp2"
  fi
done <"$db_folder/$deps_db"

tmp1=""
tmp2=""
echo "  Explicit-packages database..."
while read e; do
  tmp1=$(echo $e | cut -d' ' -f1)
  tmp2=$(echo $e | cut -d' ' -f2)
  if [ ! -z "$tmp1" -a ! -z "$tmp2" ]; then
    expl_indb["$tmp1"]="$tmp2"
  fi
done <"$db_folder/$expl_db"

unset tmp1 tmp2 e

echo "Unlocking databases..."
[ -f "$db_folder/$deps_db.lock" ] && (
  rm "$db_folder/$deps_db.lock" >/dev/null 2>&1
  if test $? -ne 0; then
    echo "ERROR: Can't unlock depency-packages database.";exit 1
  fi
)
[ -f "$db_folder/$expl_db.lock" ] && (
  rm "$db_folder/$expl_db.lock" >/dev/null 2>&1
  if test $? -ne 0; then
    echo "ERROR: Can't unlock explicit-packages database.";exit 1
  fi
)
[ -f "$db_folder/$igno_db.lock" ] && (
  rm "$db_folder/$igno_db.lock" >/dev/null 2>&1
  if test $? -ne 0; then
    echo "ERROR: Can't unlock ignore-packages database.";exit 1
  fi
)
