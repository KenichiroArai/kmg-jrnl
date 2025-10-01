package kmg.tool.one2one.application.service.impl;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;

import org.springframework.stereotype.Service;

import kmg.tool.cmn.infrastructure.exception.KmgToolMsgException;
import kmg.tool.cmn.infrastructure.types.KmgToolGenMsgTypes;
import kmg.tool.one2one.application.service.SimpleOne2OneService;

/**
 * シンプル1入力ファイルから1出力ファイルへの変換ツールサービス<br>
 *
 * @author KenichiroArai
 *
 * @since 0.1.0
 *
 * @version 0.1.0
 */
@Service
public class SimpleOne2OneServiceImpl implements SimpleOne2OneService {

    /**
     * 入力ファイルパス
     *
     * @since 0.1.0
     */
    private Path inputPath;

    /**
     * 出力ファイルパス
     *
     * @since 0.1.0
     */
    private Path outputPath;

    /**
     * 入力ファイルパスを返す<br>
     *
     * @since 0.1.0
     *
     * @return 入力ファイルパス
     */
    @Override
    public Path getInputPath() {

        final Path result = this.inputPath;
        return result;

    }

    /**
     * 出力ファイルパスを返す<br>
     *
     * @since 0.1.0
     *
     * @return 出力ファイルパス
     */
    @Override
    public Path getOutputPath() {

        final Path result = this.outputPath;
        return result;

    }

    /**
     * 初期化する
     *
     * @since 0.1.0
     *
     * @return true：成功、false：失敗
     *
     * @param inputPath
     *                   入力ファイルパス
     * @param outputPath
     *                   出力ファイルパス
     *
     * @throws KmgToolMsgException
     *                             KMGツールメッセージ例外
     */
    @SuppressWarnings("hiding")
    @Override
    public boolean initialize(final Path inputPath, final Path outputPath) throws KmgToolMsgException {

        final boolean result = true;

        this.inputPath = inputPath;
        this.outputPath = outputPath;

        return result;

    }

    /**
     * 処理する
     *
     * @since 0.1.0
     *
     * @return true：成功、false：失敗
     *
     * @throws KmgToolMsgException
     *                             KMGツールメッセージ例外
     */
    @Override
    public boolean process() throws KmgToolMsgException {

        boolean result = false;

        /* 入力から出力の処理 */

        try (final BufferedReader brInput = Files.newBufferedReader(this.inputPath);
            final BufferedWriter bwOutput = Files.newBufferedWriter(this.outputPath);) {

            String line = null;

            while ((line = brInput.readLine()) != null) {

                // クラス名とメソッド名を安全に抽出
                String    className       = "";
                String    methodName      = "";
                final int rightBracketIdx = line.indexOf("]");
                final int dotIdx          = line.indexOf(".", rightBracketIdx + 1);
                final int methodEndIdx    = line.indexOf(" --", dotIdx + 1);

                if ((rightBracketIdx == -1) || (dotIdx == -1) || (methodEndIdx == -1) || (dotIdx <= rightBracketIdx)
                    || (methodEndIdx <= dotIdx)) {

                    // パース失敗時は空文字列のまま出力
                    continue;

                }
                className = line.substring(rightBracketIdx + 1, dotIdx).trim();
                methodName = line.substring(dotIdx + 1, methodEndIdx).trim();

                final String output = className + "." + methodName;

                // 「kmg.tool」が含まれている行のみ処理
                if (!output.startsWith("kmg.tool")) {

                    continue;

                }

                // クラス名とメソッド名を出力する
                bwOutput.write(output);
                bwOutput.write(System.lineSeparator());

            }

        } catch (final IOException e) {

            // 例外をスローする
            final KmgToolGenMsgTypes msgType     = KmgToolGenMsgTypes.KMGTOOL_GEN15000;
            final Object[]           messageArgs = {};
            throw new KmgToolMsgException(msgType, messageArgs, e);

        }

        result = true;
        return result;

    }

}
