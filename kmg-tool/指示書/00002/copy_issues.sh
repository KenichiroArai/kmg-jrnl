#!/bin/bash

REPO="KenichiroArai/kmg-tool"
SOURCE_ISSUE=46

# 元 Issue の詳細情報を JSON で取得
read -r BODY ASSIGNEES LABELS MILESTONE PROJECT_IDS PARENT <<<$(gh issue view $SOURCE_ISSUE --repo $REPO \
  --json body,assignees,labels,milestone,projects,number \
  --jq '[
    .body,
    ( .assignees | map(.login) | join(",") ),
    ( .labels | map(.name) | join(",") ),
    ( .milestone.title // "" ),
    ( .projects | map(.id) | join(",") ),
    .number
  ] | @tsv')

# タイトル一覧
TITLES=(
  "kmg.tool.cmnのJavadocの整備"
  "kmg.tool.dtcのJavadocの整備"
  "kmg.tool.e2sccのJavadocの整備"
  "kmg.tool.fldcrtのJavadocの整備"
  "kmg.tool.ifacccrtのJavadocの整備"
  "kmg.tool.iitoのJavadocの整備"
  "kmg.tool.inputのJavadocの整備"
  "kmg.tool.ioのJavadocの整備"
  "kmg.tool.isのJavadocの整備"
  "kmg.tool.jdoc.domainのJavadocの整備"
  "kmg.tool.jdocrのJavadocの整備"
  "kmg.tool.jdtsのJavadocの整備"
  "kmg.tool.mptfのJavadocの整備"
  "kmg.tool.msgtpcrtのJavadocの整備"
  "kmg.tool.one2oneのJavadocの整備"
  "kmg.tool.simpleのJavadocの整備"
  "kmg.tool.two2oneのJavadocの整備"
  "kmg.tool.valのJavadocの整備"
)

for title in "${TITLES[@]}"; do
  echo "Creating issue: $title"

  # Issue 作成
  ISSUE_URL=$(gh issue create --repo "$REPO" \
    --title "$title" \
    --body "$BODY" \
    ${ASSIGNEES:+--assignee "$ASSIGNEES"} \
    ${LABELS:+--label "$LABELS"} \
    ${MILESTONE:+--milestone "$MILESTONE"} \
    --json url \
    --jq .url)

  echo "Created: $ISSUE_URL"

  # プロジェクトの追加（必要ならカスタムフィールド設定も）
  if [[ -n "$PROJECT_IDS" ]]; then
    for pid in ${PROJECT_IDS//,/ }; do
      echo "Adding to project: $pid"
      gh project item-add "$pid" --url "$ISSUE_URL"
      # カスタムフィールドは gh project item-edit で追加設定が必要
    done
  fi

  # Parent Issue との関連付け
  if [[ -n "$PARENT" ]]; then
    echo "Linking to parent issue: #$PARENT"
    gh issue edit "$ISSUE_URL" --add-link "$REPO#${PARENT}"
  fi

  echo "---"
done

echo "All issues created successfully!"
