import org.gradle.api.tasks.compile.JavaCompile

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Wycisza ostrzeżenia javac „source/target value 8 is obsolete” z wtyczek bez podniesionego `compileOptions`
// (bez zmiany wersji bytecode — bezpieczniej niż ręczna zmiana `JavaCompile` przy AGP).
subprojects {
    tasks.withType<JavaCompile>().configureEach {
        val args = options.compilerArgs
        if (args.none { it == "-Xlint:-options" }) {
            args.add("-Xlint:-options")
        }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
