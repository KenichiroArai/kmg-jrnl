#!/bin/bash

REPO="KenichiroArai/kmg-tool"
SOURCE_ISSUE=46

echo "元Issue #$SOURCE_ISSUE の情報を取得中..."

# 元 Issue の詳細情報を取得
ISSUE_INFO=$(gh issue view $SOURCE_ISSUE --repo $REPO --json body,assignees,labels,milestone,projectItems,number)

# 各情報を抽出
BODY=$(echo "$ISSUE_INFO" | jq -r '.body // ""')
ASSIGNEES=$(echo "$ISSUE_INFO" | jq -r '.assignees | map(.login) | join(",") // ""')
LABELS=$(echo "$ISSUE_INFO" | jq -r '.labels | map(.name) | join(",") // ""')
MILESTONE=$(echo "$ISSUE_INFO" | jq -r '.milestone.title // ""')
PROJECT_ITEMS=$(echo "$ISSUE_INFO" | jq -r '.projectItems | map(.project.id) | join(",") // ""')
PARENT=$(echo "$ISSUE_INFO" | jq -r '.number // ""')

echo "取得完了:"
echo "  Body: ${BODY:0:50}..."
echo "  Assignees: $ASSIGNEES"
echo "  Labels: $LABELS"
echo "  Milestone: $MILESTONE"
echo "  Project Items: $PROJECT_ITEMS"
echo "  Parent: $PARENT"
echo ""

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

  # Issue 作成コマンドを構築
  CREATE_CMD="gh issue create --repo \"$REPO\" --title \"$title\" --body \"$BODY\""

  # オプションを追加
  if [[ -n "$ASSIGNEES" ]]; then
    IFS=',' read -ra ASSIGNEE_ARRAY <<< "$ASSIGNEES"
    for assignee in "${ASSIGNEE_ARRAY[@]}"; do
      CREATE_CMD="$CREATE_CMD --assignee \"$assignee\""
    done
  fi

  if [[ -n "$LABELS" ]]; then
    IFS=',' read -ra LABEL_ARRAY <<< "$LABELS"
    for label in "${LABEL_ARRAY[@]}"; do
      CREATE_CMD="$CREATE_CMD --label \"$label\""
    done
  fi

  if [[ -n "$MILESTONE" ]]; then
    CREATE_CMD="$CREATE_CMD --milestone \"$MILESTONE\""
  fi

  # Issue 作成
  echo "実行コマンド: $CREATE_CMD"
  ISSUE_URL=$(eval $CREATE_CMD)

  if [[ $? -eq 0 ]]; then
    echo "Created: $ISSUE_URL"

    # プロジェクトの追加
    if [[ -n "$PROJECT_ITEMS" ]]; then
      IFS=',' read -ra PROJECT_ARRAY <<< "$PROJECT_ITEMS"
      for project_id in "${PROJECT_ARRAY[@]}"; do
        echo "Adding to project: $project_id"
        gh project item-add "$project_id" --url "$ISSUE_URL" || echo "プロジェクト追加に失敗しました"
      done
    fi

    # Parent Issue との関連付け
    if [[ -n "$PARENT" ]]; then
      echo "Linking to parent issue: #$PARENT"
      gh issue edit "$ISSUE_URL" --add-link "$REPO#${PARENT}" || echo "親Issueとの関連付けに失敗しました"
    fi
  else
    echo "Issue作成に失敗しました"
  fi

  echo "---"
done

echo "All issues created successfully!"
