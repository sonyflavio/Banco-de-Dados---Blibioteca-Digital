# Sistema de Biblioteca Digital 📚

Um sistema completo de gerenciamento de biblioteca digital desenvolvido como projeto acadêmico de banco de dados, demonstrando conceitos avançados de modelagem, implementação e otimização.

## 🎯 Visão Geral

Este projeto implementa um sistema robusto para gerenciamento de bibliotecas digitais, cobrindo desde o controle de acervo até o gerenciamento de usuários e empréstimos. O sistema foi projetado seguindo as melhores práticas de banco de dados relacionais e inclui funcionalidades avançadas como sistema de recomendação e controle de acesso granular.

## ✨ Funcionalidades Principais

### 👥 Gerenciamento de Usuários
- Cadastro de usuários com diferentes perfis (estudante, professor, funcionário)
- Controle de status e permissões
- Histórico de atividades

### 📖 Controle de Acervo
- Catalogação completa de livros, artigos, revistas e teses
- Informações bibliográficas detalhadas
- Controle de disponibilidade em tempo real
- Relacionamentos entre autores e categorias

### 🔄 Sistema de Empréstimos
- Processamento de empréstimos e devoluções
- Controle automático de prazos
- Sistema de multas por atraso
- Renovações automáticas

### 🔍 Busca Avançada
- Busca por título, autor, categoria ou ISBN
- Filtros múltiplos combinados
- Resultados otimizados com índices

### 📊 Relatórios e Analytics
- Estatísticas de uso do acervo
- Relatórios de empréstimos por período
- Análise de popularidade de itens

## 🛠️ Tecnologias Utilizadas

- **Banco de Dados:** PostgreSQL 14+
- **Linguagem:** SQL (DDL/DML/DCL)
- **Ferramentas:** pgAdmin, DBeaver
- **Documentação:** Markdown, Draw.io (diagramas)

## 📋 Pré-requisitos

- PostgreSQL 14 ou superior
- Cliente SQL (pgAdmin, DBeaver, ou similar)
- Conhecimento básico em SQL

## 🚀 Instalação e Configuração

### 1. Configuração do Banco de Dados

```bash
# Conectar ao PostgreSQL
psql -U postgres

# Criar usuário do projeto
CREATE USER biblioteca_user WITH PASSWORD 'sua_senha_aqui';

# Criar banco de dados
CREATE DATABASE biblioteca_digital OWNER biblioteca_user;

# Conceder privilégios
GRANT ALL PRIVILEGES ON DATABASE biblioteca_digital TO biblioteca_user;
```

### 2. Execução dos Scripts

```bash
# Conectar ao banco criado
psql -U biblioteca_user -d biblioteca_digital

# Executar script de criação das tabelas
\i scripts/01_create_tables.sql

# Inserir dados de exemplo
\i scripts/02_insert_sample_data.sql

# Criar índices de performance
\i scripts/03_create_indexes.sql
```

### 3. Verificação da Instalação

```sql
-- Verificar se todas as tabelas foram criadas
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public';

-- Verificar dados de exemplo
SELECT COUNT(*) FROM usuario;
SELECT COUNT(*) FROM item;
```

## 📁 Estrutura do Projeto

```
biblioteca-digital/
├── README.md
├── docs/
│   ├── projeto_completo.md
│   ├── modelo_conceitual.png
│   ├── modelo_logico.png
│   └── dicionario_dados.md
├── scripts/
│   ├── 01_create_tables.sql
│   ├── 02_insert_sample_data.sql
│   ├── 03_create_indexes.sql
│   └── 04_create_views.sql
├── queries/
│   ├── consultas_basicas.sql
│   ├── consultas_avancadas.sql
│   └── relatorios.sql
└── tests/
    ├── test_inserts.sql
    ├── test_constraints.sql
    └── test_performance.sql
```

## 🗃️ Modelo de Dados

### Entidades Principais

- **USUARIO**: Gerencia informações dos usuários do sistema
- **ITEM**: Catálogo de livros, artigos e outras mídias
- **AUTOR**: Informações dos autores das obras
- **CATEGORIA**: Classificação temática dos itens
- **EMPRESTIMO**: Controle de empréstimos e devoluções
- **RESERVA**: Sistema de reservas de itens

### Relacionamentos

- Um usuário pode ter múltiplos empréstimos (1:N)
- Um item pode ter múltiplos autores (N:M)
- Um item pode pertencer a múltiplas categorias (N:M)
- Um usuário pode fazer múltiplas reservas (1:N)

## 💡 Exemplos de Uso

### Consultas Básicas

```sql
-- Buscar todos os livros disponíveis
SELECT titulo, isbn, data_publicacao 
FROM item 
WHERE disponivel = true AND tipo_item = 'livro';

-- Verificar empréstimos ativos de um usuário
SELECT u.nome, i.titulo, e.data_emprestimo, e.data_devolucao_prevista
FROM emprestimo e
JOIN usuario u ON e.id_usuario = u.id_usuario
JOIN item i ON e.id_item = i.id_item
WHERE u.email = 'joao@email.com' AND e.status = 'ativo';
```

### Consultas Avançadas

```sql
-- Relatório de popularidade por categoria
SELECT c.nome as categoria, COUNT(e.id_emprestimo) as total_emprestimos
FROM categoria c
JOIN item_categoria ic ON c.id_categoria = ic.id_categoria
JOIN emprestimo e ON ic.id_item = e.id_item
GROUP BY c.nome
ORDER BY total_emprestimos DESC;

-- Usuários com empréstimos em atraso
SELECT u.nome, u.email, i.titulo, 
       e.data_devolucao_prevista,
       CURRENT_DATE - e.data_devolucao_prevista as dias_atraso
FROM emprestimo e
JOIN usuario u ON e.id_usuario = u.id_usuario
JOIN item i ON e.id_item = i.id_item
WHERE e.status = 'ativo' 
  AND e.data_devolucao_prevista < CURRENT_DATE;
```

## 🔧 Configurações Avançadas

### Otimização de Performance

```sql
-- Índices para consultas frequentes
CREATE INDEX idx_usuario_email ON usuario(email);
CREATE INDEX idx_item_titulo ON item(titulo);
CREATE INDEX idx_emprestimo_status ON emprestimo(status);
CREATE INDEX idx_emprestimo_data ON emprestimo(data_emprestimo);

-- View materializada para relatórios
CREATE MATERIALIZED VIEW mv_estatisticas_mensais AS
SELECT 
    DATE_TRUNC('month', data_emprestimo) as mes,
    COUNT(*) as total_emprestimos,
    COUNT(DISTINCT id_usuario) as usuarios_ativos
FROM emprestimo
GROUP BY DATE_TRUNC('month', data_emprestimo);
```

### Segurança e Controle de Acesso

```sql
-- Roles para diferentes tipos de usuário
CREATE ROLE bibliotecario;
CREATE ROLE usuario_comum;

-- Permissões específicas
GRANT SELECT, INSERT, UPDATE ON emprestimo TO bibliotecario;
GRANT SELECT ON item TO usuario_comum;
```

## 🧪 Testes

Execute os testes para validar o funcionamento:

```bash
# Testes de integridade
psql -U biblioteca_user -d biblioteca_digital -f tests/test_constraints.sql

# Testes de performance
psql -U biblioteca_user -d biblioteca_digital -f tests/test_performance.sql
```

## 📊 Monitoramento

### Queries de Monitoramento

```sql
-- Verificar tamanho das tabelas
SELECT schemaname, tablename, 
       pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Verificar índices utilizados
SELECT schemaname, tablename, attname, n_distinct, correlation
FROM pg_stats
WHERE schemaname = 'public';
```

## 🔮 Funcionalidades Futuras

- [ ] Sistema de recomendação baseado em ML
- [ ] API REST para integração com aplicações web
- [ ] Dashboard em tempo real
- [ ] Integração com sistemas de pagamento para multas
- [ ] Notificações automáticas via email/SMS
- [ ] Sistema de avaliações e resenhas
- [ ] Controle de acesso por biometria
- [ ] Backup automático na nuvem

## 🤝 Contribuição

1. Faça um fork do projeto
2. Crie uma branch para sua feature (`git checkout -b feature/nova-funcionalidade`)
3. Commit suas mudanças (`git commit -am 'Adiciona nova funcionalidade'`)
4. Push para a branch (`git push origin feature/nova-funcionalidade`)
5. Abra um Pull Request


## 👨‍💻 Autor

**Seu Nome**
- Email: sonyflavio@gmail.com
- LinkedIn: [seu-perfil](https://www.linkedin.com/in/flavio-serra/)
- GitHub: [@seu-usuario](https://github.com/sonyflavio)

## 🙏 Agradecimentos

- Professores e orientadores do curso de Banco de Dados
- Comunidade PostgreSQL pela excelente documentação
- Colegas de turma pelas discussões e feedback
- Bibliotecários consultados durante o levantamento de requisitos

---

## 📚 Referências

1. **SILBERSCHATZ, A.; GALVIN, P. B.; GAGNE, G.** *Database System Concepts*. 7th ed. McGraw-Hill, 2019.
2. **ELMASRI, R.; NAVATHE, S.** *Fundamentals of Database Systems*. 7th ed. Pearson, 2016.
3. **PostgreSQL Documentation** - https://www.postgresql.org/docs/

---

