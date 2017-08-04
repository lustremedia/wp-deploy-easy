echo "installing ruby environment with bundler\n"
bundle install

echo "Removing wp-deploy-easy git reference\n"
rm -rf .git

echo "Initializing local git repository\n"
git init

echo "Attaching latest stable wordpress as git submodule\n"
rm -rf wordpress
git submodule add https://github.com/WordPress/WordPress.git wordpress
cd wordpress
git checkout $(git tag -l --sort -version:refname | head -n 1)
cd ..

echo "Cleanup wp-deploy-easy\n"
rm README.md
echo "Removing wp-deploy-easy github remote\n"
git remote rm origin

echo "Doing first local commit, yay!\n"
git add -A
git commit -m "Inital commit"

echo "Adding local repository to remote.\n"
git remote add origin <your external repo url>
git push -u origin master

echo "Setting up development branch locally and pushing it remote\n"
git checkout -b development
git push -u origin development
