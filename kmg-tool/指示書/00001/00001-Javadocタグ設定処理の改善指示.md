# Javadocタグ設定処理の改善指示

## 概要
Javadocタグの処理をより制御しやすくするため、タグ処理のロジックを改善する。

## 修正内容

### 1. JdtsBlockReplLogicインターフェースの拡張

`kmg-tool/src/main/java/kmg/tool/application/logic/JdtsBlockReplLogic.java`インターフェースに以下のメソッドを追加：

```java
/**
 * 次のJavadocタグを取得する<br>
 *
 * @author KenichiroArai
 * @since 0.1.0
 * @return 次のJavadocタグ設定モデル、存在しない場合はnull
 */
JdaTagConfigModel getNextTag();

/**
 * 現在のタグが存在するか確認する<br>
 *
 * @author KenichiroArai
 * @since 0.1.0
 * @return true：存在する場合、false：存在しない場合
 */
boolean hasExistingTag();

/**
 * 現在のタグを削除する<br>
 *
 * @author KenichiroArai
 * @since 0.1.0
 * @return true：成功、false：失敗
 */
boolean removeCurrentTag();

/**
 * 現在のタグを更新する<br>
 *
 * @author KenichiroArai
 * @since 0.1.0
 * @return true：成功、false：失敗
 */
boolean updateCurrentTag();

/**
 * 新しいタグを処理する<br>
 *
 * @author KenichiroArai
 * @since 0.1.0
 * @param tag Javadoc追加のタグ設定モデル
 * @return true：成功、false：失敗
 */
boolean processNewTag(JdaTagConfigModel tag);
```

### 2. JdtsBlockReplLogicImplの実装追加

`kmg-tool/src/main/java/kmg/tool/application/logic/impl/JdtsBlockReplLogicImpl.java`に以下を追加：

```java
/**
 * タグイテレータ
 */
private Iterator<JdaTagConfigModel> tagIterator;

/**
 * 現在のタグ
 */
private JdaTagConfigModel currentTag;

/**
 * 現在の既存タグ
 */
private JavadocTagModel currentExistingTag;

/**
 * 初期化する<br>
 *
 * @author KenichiroArai
 * @since 0.1.0
 * @param jdtsConfigsModel JDTSの設定モデル
 * @param jdtsBlockModel JDTSのブロックモデル
 * @return true：成功、false：失敗
 * @throws KmgToolException KMGツール例外
 */
@Override
public boolean initialize(final JdtsConfigsModel jdtsConfigsModel, final JdtsBlockModel jdtsBlockModel)
    throws KmgToolException {
    boolean result = false;

    result = super.initialize(jdtsConfigsModel, jdtsBlockModel);
    if (!result) {
        return result;
    }

    this.tagIterator = this.jdtsConfigsModel.getJdaTagConfigModels().iterator();
    this.currentTag = null;
    this.currentExistingTag = null;

    return result;
}

/**
 * 次のJavadocタグを取得する<br>
 *
 * @author KenichiroArai
 * @since 0.1.0
 * @return 次のJavadocタグ設定モデル、存在しない場合はnull
 */
@Override
public JdaTagConfigModel getNextTag() {
    JdaTagConfigModel result = null;

    if (!this.tagIterator.hasNext()) {
        return result;
    }

    this.currentTag = this.tagIterator.next();
    this.currentExistingTag = this.jdtsBlockModel.getJavadocModel()
        .getJavadocTagsModel().findByTag(this.currentTag.getTag());
    result = this.currentTag;

    return result;
}

/**
 * 現在のタグが存在するか確認する<br>
 *
 * @author KenichiroArai
 * @since 0.1.0
 * @return true：存在する場合、false：存在しない場合
 */
@Override
public boolean hasExistingTag() {
    boolean result = false;

    result = this.currentExistingTag != null;

    return result;
}

/**
 * 現在のタグを削除する<br>
 *
 * @author KenichiroArai
 * @since 0.1.0
 * @return true：成功、false：失敗
 */
@Override
public boolean removeCurrentTag() {
    boolean result = false;

    if (this.currentExistingTag == null) {
        return result;
    }

    this.replacedJavadocBlock = this.replacedJavadocBlock
        .replace(this.currentExistingTag.getTargetStr(), KmgString.EMPTY);
    result = true;

    return result;
}

/**
 * 現在のタグを更新する<br>
 *
 * @author KenichiroArai
 * @since 0.1.0
 * @return true：成功、false：失敗
 */
@Override
public boolean updateCurrentTag() {
    boolean result = false;

    if (this.currentTag == null || this.currentExistingTag == null) {
        return result;
    }

    this.updateExistingTag(this.currentTag, this.currentExistingTag);
    result = true;

    return result;
}
```

### 3. JdtsReplServiceImplの実装修正

`kmg-tool/src/main/java/kmg/tool/application/service/impl/JdtsReplServiceImpl.java`の`replace`メソッドを以下のように修正：

```java
/**
 * 内容を置換した値を返す。<br>
 *
 * @author KenichiroArai
 * @since 0.1.0
 * @return true：成功、false：失敗
 * @throws KmgToolException KMGツール例外
 */
@Override
public boolean replace() throws KmgToolException {
    boolean result = false;

    /* オリジナルコードのJavadocブロック部分を識別子に置換する */
    // 同じJavadocがある場合に異なる置換をしないため、事前に一意となる識別子に置き換える
    for (final JdtsBlockModel jdtsBlockModel : this.jdtsCodeModel.getJdtsBlockModels()) {
        // 複数該当する場合もあるため、最初の部分のみを置換する
        this.replaceCode = this.replaceCode.replaceFirst(
            Pattern.quote(jdtsBlockModel.getJavadocModel().getSrcJavadoc()), jdtsBlockModel.getId().toString());
    }

    /* 識別子を置換後のJavadocブロックに置換する */
    for (final JdtsBlockModel jdtsBlockModel : this.jdtsCodeModel.getJdtsBlockModels()) {
        /* Javadocタグ設定のブロック置換ロジックの初期化 */
        this.jdtsBlockReplLogic.initialize(this.jdtsConfigsModel, jdtsBlockModel);

        /* タグを順番に処理 */
        JdaTagConfigModel tag;
        while ((tag = this.jdtsBlockReplLogic.getNextTag()) != null) {
            if (!this.jdtsBlockReplLogic.hasExistingTag()) {
                // タグが存在しない場合の処理
                this.jdtsBlockReplLogic.processNewTag(tag);
                continue;
            }

            // 誤配置時の削除処理
            if (tag.getLocation().isRemoveIfMisplaced()
                && !tag.isProperlyPlaced(jdtsBlockModel.getJavaClassification())) {
                result = this.jdtsBlockReplLogic.removeCurrentTag();
                if (!result) {
                    return result;
                }
                continue;
            }

            // タグの更新処理
            result = this.jdtsBlockReplLogic.updateCurrentTag();
            if (!result) {
                return result;
            }
        }

        /* Javadocの最終的な結果を組み立てる */
        this.jdtsBlockReplLogic.buildFinalJavadoc();

        /* 置換後のJavadocブロックを取得する */
        final String replaceJavadocBlock = this.jdtsBlockReplLogic.getReplacedJavadocBlock();

        /* 置換後のJavadocブロックにコード全体に反映する */
        this.replaceCode = this.replaceCode.replace(jdtsBlockModel.getId().toString(), replaceJavadocBlock);
    }

    this.totalRows += KmgDelimiterTypes.LINE_SEPARATOR.split(this.replaceCode).length;

    result = true;
    return result;
}
```

### 4. processJavadocTagsメソッドの削除

`JdtsBlockReplLogic`インターフェースと`JdtsBlockReplLogicImpl`クラスから`processJavadocTags`メソッドを削除しました。このメソッドの機能は、より細かい粒度のメソッドに分割され、`JdtsReplServiceImpl`の`replace`メソッドで制御されるようになりました。

## 期待される効果

- タグ処理のロジックがより明確になる
- 各処理ステップが分離され、制御が容易になる
- タグ処理の順序制御が可能になる
- 処理の再利用性が向上する
- タグ処理の責務がより適切に分離される

## チェックリスト

- [x] JdtsBlockReplLogicインターフェースに新規メソッドを追加
- [x] JdtsBlockReplLogicImplに新規フィールドを追加
- [x] JdtsBlockReplLogicImplに新規メソッドを実装
- [x] JdtsReplServiceImplのreplaceメソッドを修正
- [x] processJavadocTagsメソッドを削除
