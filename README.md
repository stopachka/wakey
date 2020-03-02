# wakey

- Make sure you have Xcode 11
- Make sure you have cocoapods 
    - (this is the external dependency manager. There is a new standard one for Swift, but Firebase doesn't work on that yet)
    - `sudo gem install cocoapods`
- Open `wakey.xcworkspace` in Xcode

# deploying the site

In your repo root, run

```
git checkout -B gh-pages
git add -f web
git commit -am "Rebuild website"
git filter-branch -f --prune-empty --subdirectory-filter web
git push -f origin gh-pages
git checkout -
```