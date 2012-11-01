coffee -o compiled -c calc.coffee
haml index.haml compiled/index.html
sass style.sass compiled/style.css
echo "Done - compiled to compiled/"
