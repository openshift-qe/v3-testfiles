secretfiles=$(ls -1 logging-old-*)
for filename in ${secretfiles}; do
  echo "check ${filename//old-}"
  diff $filename ${filename//old/new} >/dev/zero
  echo $?
done
