# -----------------------------
# Cloud Build Deployment
# -----------------------------

function deploy () {
  tagName=$1
  deleteLocal=$(git tag --list | grep -q "${tagName}$" && echo "true" || echo "false")
  deleteRemote=$(git ls-remote --tags | grep -q "${tagName}$" && echo "true" || echo "false")

  if [ $deleteLocal = "true" ]; then
    git tag -d $tagName
  fi

  if [ $deleteRemote = "true" ]; then
    git push --delete origin $tagName
  fi

  echo "Creating '${tagName}' tag"
  git tag $tagName
  echo "Publish '${tagName}' tag"
  git push origin $tagName
}

function deploy-stg () {
  tagName=$1
  if [[ -z $tagName ]]; then
    tagName=$(whoami)
  fi

  deploy "stg-${tagName}"
}

function deploy-prd () {
  deploy "prd-${1:-$(date +%FT%TZ)}"
}

# -----------------------------
